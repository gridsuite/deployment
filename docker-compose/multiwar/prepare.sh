#!/usr/bin/env bash
#
# prepare.sh — Build WAR files and populate webapps/ for Docker Tomcat.
#
# Usage:
#   ./prepare.sh [--skip-build]
#
# Prerequisites:
#   - Java 17+ and Maven 3.8+ installed
#   - Server submodules checked out
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAR_DEPLOY="$(cd "$SCRIPT_DIR" && realpath ../../../../tools/war-deploy/war-deploy.sh)"
WEBAPPS_DIR="$SCRIPT_DIR/webapps"

SKIP_BUILD=false
[[ "${1:-}" == "--skip-build" ]] && SKIP_BUILD=true

if ! $SKIP_BUILD; then
    echo "=== Building WARs (this may take a while)... ==="
    "$WAR_DEPLOY" --build --docker
fi

echo "=== Copying WARs to webapps/ ==="
rm -rf "$WEBAPPS_DIR"
mkdir -p "$WEBAPPS_DIR"

WRAPPERS_DIR="$(dirname "$WAR_DEPLOY")/war-wrappers"
for war in "$WRAPPERS_DIR"/*/target/*.war; do
    [[ -f "$war" ]] || continue
    cp "$war" "$WEBAPPS_DIR/"
    echo "  $(basename "$war")"
done

echo "=== Copying per-WAR config overrides ==="
rm -rf "$SCRIPT_DIR/config"
if [[ -d "$WRAPPERS_DIR/config" ]]; then
    cp -r "$WRAPPERS_DIR/config" "$SCRIPT_DIR/config"
    echo "  $(ls "$SCRIPT_DIR/config" | wc -l) server configs copied"
fi

COUNT=$(ls -1 "$WEBAPPS_DIR"/*.war 2>/dev/null | wc -l)
echo "=== Done: $COUNT WARs copied to webapps/ ==="
echo ""
echo "Now run: docker compose up"
