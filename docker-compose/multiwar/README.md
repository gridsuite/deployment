# WAR Deploy Tool

Generated with little supervision by opus4.6.

Builds GridSuite microservices as WAR files for docker-compose deployment, **without modifying any original source files**.

## How it works

Instead of patching server sources, this tool generates **wrapper Maven projects** that:
1. Depend on the original server JAR (classes artifact)
2. Add a generated `SpringBootServletInitializer` class that delegates to the original Application class
3. Package everything as a WAR with a clean context-path name

```
Original server (unmodified)          Wrapper project (generated)
┌─────────────────────────┐          ┌─────────────────────────┐
│ report-server/          │          │ war-wrappers/report-server/
│   pom.xml (jar)         │◄─────────│   pom.xml (war)         │
│   ReportApplication.java│          │   WarInitializer.java   │
└─────────────────────────┘          └─────────────────────────┘
         │                                      │
         ▼                                      ▼
  gridsuite-report-server.jar          report-server.war
```

## Quick Start

```bash
# Build all WARs and prepare for docker-compose
./wars.sh

# Start the stack
docker compose up
```

## Enabling/disabling servers

Edit the `MANIFEST` array in `war-deploy.sh`. Comment lines with `#` to disable:

```bash
"actions-server|actions-server||..."       # enabled
#"timeseries-server|timeseries-server||..." # disabled
```

## Prerequisites

- Java 21+
- Maven 3.8+
- Server submodules checked out and buildable in the layout of Gridsuite Aggregator

## Excluded (Boot WebFlux — incompatible(??) with WAR)

- config-server
- config-notification-server
- directory-notification-server
- merge-notification-server
- study-notification-server
- gateway
