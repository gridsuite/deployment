#!/usr/bin/env bash
#
# Build the selected Spring Boot servers as WARs for the local multi-WAR
# Tomcat. Kubernetes keeps using the normal executable JAR/Jib Docker build.
#
# Usage:
#   ./wars.sh [--only SERVER]...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGGREGATOR_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
BACKEND_ROOT="$AGGREGATOR_ROOT/backend"
WEBAPPS_DIR="$SCRIPT_DIR/gen/wars"
CONFIG_DIR="$SCRIPT_DIR/gen/war-configs"
INITIALIZER_SOURCE="$SCRIPT_DIR/war-support/GenericWarInitializer.java"
MAP_CONFIG="$SCRIPT_DIR/nonwars-to-tomcat-config/common-application.yml"
LIST_CONFIG="$SCRIPT_DIR/nonwars-to-tomcat-config/common-application-list.yml"

ONLY_SERVERS=()

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --only)
            [[ $# -ge 2 ]] || { echo "Missing server name after --only" >&2; exit 1; }
            ONLY_SERVERS+=("$2")
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

log() {
    printf '\033[1;34m[WAR]\033[0m %s\n' "$*"
}

error() {
    printf '\033[1;31m[ERR]\033[0m %s\n' "$*" >&2
}

# Format: Tomcat context path|server module path below backend/servers.
MANIFEST=(
    "actions-server|actions-server"
    "directory-server|directory-server"
    "explore-server|explore-server"
    "filter-server|filter-server"
    "geo-data-server|geo-data-server"
    "loadflow-server|loadflow-server"
    "network-map-server|network-map-server"
    "network-modification-server|network-modification-server"
    "network-store-server|powsybl-network-store-server/network-store-server"
    "case-server|powsybl-case-server"
    "network-conversion-server|powsybl-network-conversion-server"
    "single-line-diagram-server|powsybl-single-line-diagram-server"
    "report-server|report-server"
    "security-analysis-server|security-analysis-server"
    "sensitivity-analysis-server|sensitivity-analysis-server"
    "shortcircuit-server|shortcircuit-server"
    "study-config-server|study-config-server"
    "study-server|study-server"
    "user-admin-server|user-admin-server"
    "user-identity-server|user-identity-oidc-replication-server"
    "voltage-init-server|voltage-init-server"
)

should_process() {
    local context="$1"
    if [[ ${#ONLY_SERVERS[@]} -eq 0 ]]; then
        return 0
    fi

    local selected
    for selected in "${ONLY_SERVERS[@]}"; do
        [[ "$selected" == "$context" ]] && return 0
    done
    return 1
}

manifest_entry() {
    local context="$1"
    local entry
    for entry in "${MANIFEST[@]}"; do
        [[ "${entry%%|*}" == "$context" ]] && {
            printf '%s\n' "$entry"
            return 0
        }
    done
    return 1
}

validate_selection() {
    local selected
    for selected in "${ONLY_SERVERS[@]}"; do
        manifest_entry "$selected" >/dev/null || {
            error "Unknown server: $selected"
            exit 1
        }
    done
}

selected_projects() {
    local entry context module_path
    local projects=()

    for entry in "${MANIFEST[@]}"; do
        IFS='|' read -r context module_path <<< "$entry"
        should_process "$context" || continue
        projects+=("servers/$module_path")
    done

    local IFS=,
    printf '%s\n' "${projects[*]}"
}

build_executable_jars() {
    local projects
    projects="$(selected_projects)"
    [[ -n "$projects" ]] || {
        error "No servers selected"
        exit 1
    }

    local -a mvn
    if command -v mvnd >/dev/null 2>&1; then
        mvn=(mvnd)
    else
        mvn=(mvn -T2.0C -q)
    fi

    log "Building Spring Boot executable JARs"
    (
        cd "$BACKEND_ROOT"
        "${mvn[@]}" -pl "$projects" -am package -DskipTests
    )
}

executable_jar() {
    local module_dir="$1"
    local jar
    jar="$(find "$module_dir/target" -maxdepth 1 -type f -name '*-exec.jar' -print -quit 2>/dev/null || true)"
    [[ -n "$jar" ]] || {
        error "No executable JAR found in $module_dir/target"
        exit 1
    }
    printf '%s\n' "$jar"
}

start_class() {
    local jar="$1"
    unzip -p "$jar" META-INF/MANIFEST.MF |
        awk -F': ' '$1 == "Start-Class" { gsub(/\r/, "", $2); print $2; exit }'
}

build_war() {
    local context="$1"
    local module_path="$2"
    local module_dir="$BACKEND_ROOT/servers/$module_path"
    local executable
    executable="$(executable_jar "$module_dir")"

    local application_class
    application_class="$(start_class "$executable")"
    [[ -n "$application_class" ]] || {
        error "No Start-Class found in $executable"
        exit 1
    }

    local output="$WEBAPPS_DIR/$context.war"
    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/grid-wAR.XXXXXX")"

    log "Packaging $context.war from ${executable##*/}"
    (
        trap 'rm -rf "$work"' EXIT

        unzip -q "$executable" -d "$work"
        mkdir -p "$work/WEB-INF/classes" "$work/WEB-INF/lib"
        cp -a "$work/BOOT-INF/classes/." "$work/WEB-INF/classes/"
        cp -a "$work/BOOT-INF/lib/." "$work/WEB-INF/lib/"
        rm -rf "$work/BOOT-INF" "$work/org"

        mkdir -p "$work/WEB-INF/classes/META-INF"
        printf '%s\n' "$application_class" \
            > "$work/WEB-INF/classes/META-INF/war-start-class"

        javac --release 21 \
            -proc:none \
            -cp "$work/WEB-INF/lib/*" \
            -d "$work/WEB-INF/classes" \
            "$INITIALIZER_SOURCE"

        jar --create --file "$output" \
            -C "$work" META-INF \
            -C "$work" WEB-INF
    )

    write_war_config "$context" "$executable"
}

write_war_config() {
    local context="$1"
    local executable="$2"
    local template="$MAP_CONFIG"
    local local_config
    local_config="$(unzip -Z1 "$executable" |
        grep -E 'BOOT-INF/classes/application-local\.(yml|yaml)$' | head -1 || true)"

    if [[ -n "$local_config" ]] &&
        unzip -p "$executable" "$local_config" |
            grep -E '^[[:space:]]+-[[:space:]]*(name:|$)' >/dev/null; then
        template="$LIST_CONFIG"
    fi

    mkdir -p "$CONFIG_DIR/$context"
    cp "$template" "$CONFIG_DIR/$context/application.yml"
}

deploy_wars() {
    local entry context module_path
    rm -f "$WEBAPPS_DIR"/*.war
    rm -rf "$CONFIG_DIR"
    mkdir -p "$WEBAPPS_DIR"

    for entry in "${MANIFEST[@]}"; do
        IFS='|' read -r context module_path <<< "$entry"
        should_process "$context" || continue
        build_war "$context" "$module_path"
    done

    log "WARs ready in $WEBAPPS_DIR"
}

[[ -f "$INITIALIZER_SOURCE" ]] || {
    error "Missing WAR initializer: $INITIALIZER_SOURCE"
    exit 1
}

validate_selection
build_executable_jars
deploy_wars
