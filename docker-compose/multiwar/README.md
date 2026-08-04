# Local Multi-WAR Deployment

Builds the Spring Boot MVC servers as WAR files for the local Docker Compose
Tomcat without changing the server sources or their Kubernetes Docker build.

The script first builds the normal Spring Boot executable JARs. It then moves
their already-resolved `BOOT-INF/classes` and `BOOT-INF/lib` contents into the
standard WAR layout and adds one shared servlet initializer. It selects the
matching map/list service configuration for each WAR. This avoids generated
Maven projects, dependency-tree comparison, and YAML parsing.

## Quick Start

```bash
# Build all WARs and prepare for Docker Compose
./wars.sh

# Build only selected servers
./wars.sh --only study-server --only network-store-server

# Start the local stack
docker compose up
```

## Enabling/disabling servers

Edit the `MANIFEST` array in `wars.sh` to add or remove local WAR servers.

```bash
"actions-server|actions-server"       # enabled
```

## Prerequisites

- Java 21+
- Maven 3.8+
- Server modules checked out and buildable in the layout of the Gridsuite
  Aggregator

## Kubernetes images

Kubernetes is unaffected by this local WAR tooling. Its deployments continue to
use the Docker images produced by the normal Maven/Jib build. The WAR script is
only for the `docker-compose/multiwar` local profile.
