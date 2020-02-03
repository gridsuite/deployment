# PowSyBl deployment

## Study application local install

### Cassandra install

Download the last version of [Cassandra](http://www.apache.org/dyn/closer.lua/cassandra/3.11.5/apache-cassandra-3.11.5-bin.tar.gz)

In order to be accessible from k8s cluster, Cassandra has to be bind to one the ip address of the machine.  The following variables have to be modified in conf/cassandra.yaml before starting the Cassandra daemon.

```yaml
seed_provider:
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
      parameters:
          - seeds: "<YOUR_IP>"

listen_address: "<YOUR_IP>"

rpc_address: "0.0.0.0"

broadcast_rpc_address: "<YOUR_IP>"
```

## Cassandra scheme setup

```bash
cqlsh <YOUR_IP>
```

To create keyspaces in a single node cluster:

```sql
CREATE KEYSPACE IF NOT EXISTS iidm WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS geo_data WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1};
CREATE KEYSPACE IF NOT EXISTS study WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
```

Then copy paste following files content to cqlsh shell:
```html
https://github.com/powsybl/powsybl-network-store/blob/master/network-store-server/src/main/resources/iidm.cql
https://github.com/powsybl/powsybl-geo-data/blob/master/geo-data-server/src/main/resources/geo_data.cql
https://github.com/powsybl/powsybl-study-server/blob/master/src/main/resources/study.cql
```

### Minikube and kubectl setup

Download and install [minikube](https://kubernetes.io/fr/docs/tasks/tools/install-minikube/) and [kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/).

Start minikube and activate ingress support:
```bash
minikube start --memory 8192
minikube addons enable ingress
```

Verify everything is ok with:
```bash
minikube status
minikube kubectl cluster-info
```

### K8s deployment

Clone deployment repository:
```bash 
git clone https://github.com/powsybl/powsybl-deployment.git
cd powsybl-deployment
```

Change Cassandra daemon ip address in k8s/overlays/local/cassandra.properties
```properties
cassandra.contact-points: "<YOUR_IP>"
cassandra.port: 9042
```

Deploy k8s services:
```bash 
kubectl apply -k k8s/overlays/local
```

Verify all services and pods have been correctly started:
```bash 
kubectl get all
```

### Swagger UI

You can now access to the swagger UI of all the Spring services:

```bash 
MINIKUBE_IP=`minikube ip`
```

```html
http://<MINIKUBE_IP>/case-server/swagger-ui.html
http://<MINIKUBE_IP>/geo-data-server/swagger-ui.html
http://<MINIKUBE_IP>/network-conversion-server/swagger-ui.html
http://<MINIKUBE_IP>/network-store-server/swagger-ui.html
http://<MINIKUBE_IP>/network-map-server/swagger-ui.html
http://<MINIKUBE_IP>/single-line-diagram-server/swagger-ui.html
http://<MINIKUBE_IP>/study-server/swagger-ui.html
```
