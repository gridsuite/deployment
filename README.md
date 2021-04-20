# GridSuite deployment

## Gridsuite local install

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

To start the cassandra server: `cd /path/to/cassandra/folder`
then `bin/cassandra -f`

### Cassandra schema setup

```bash
$ bin/cqlsh
```

To create keyspaces in a single node cluster:

```cql
CREATE KEYSPACE IF NOT EXISTS iidm WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS geo_data WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1};
CREATE KEYSPACE IF NOT EXISTS merge_orchestrator WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS cgmes_boundary WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS cgmes_assembling WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS sa WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS config WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1};
```

Then copy paste following files content to cqlsh shell:
```html
https://github.com/powsybl/powsybl-network-store/blob/master/network-store-server/src/main/resources/iidm.cql
https://github.com/powsybl/powsybl-geo-data/blob/master/geo-data-server/src/main/resources/geo_data.cql
https://github.com/gridsuite/merge-orchestrator/blob/master/src/main/resources/merge_orchestrator.cql
https://github.com/gridsuite/cgmes-boundary-server/blob/master/src/main/resources/cgmes_boundary.cql
https://github.com/gridsuite/cgmes-assembling-job/blob/master/src/main/resources/cgmes_assembling.cql
https://github.com/gridsuite/security-analysis-server/blob/master/src/main/resources/sa.cql
https://github.com/gridsuite/config-server/blob/master/src/main/resources/config.cql
```

### PostgresSql installation

Postgresql is not as easy as cassandra to download and just run in its folder, but it's almost as easy. 
To get a postgresql folder where you can just run postgresql, you have to compile from source (very easy because there 
are almost no compilation dependencies) and run an init command once. If you prefer other methods, 
feel free to install and run postgresql with your system package manager or with a dedicate docker container.

**Postgres local Installation from code sources:**

Download code sources from the following link: https://www.postgresql.org/ftp/source/v13.1/
 then unzip the downloaded file. For the simplest installation, copy paste the following commands in the unzipped folder (you can change POSTGRES_HOME if you want): 

```shell
#!/bin/bash
POSTGRES_HOME="$HOME/postgres";
./configure --without-readline --without-zlib --prefix="$POSTGRES_HOME";
make;
make install;
cd "$POSTGRES_HOME";
bin/initdb -D ./data;
echo "host  all  all 0.0.0.0/0 md5" >> data/pg_hba.conf;
bin/pg_ctl -D ./data start;
bin/psql postgres -c  "CREATE USER postgres WITH PASSWORD 'postgres' SUPERUSER;";
bin/pg_ctl -D ./data stop;
```

To start the server each time you want to work, cd in the POSTGRES_HOME folder you used during install and run
```shell
$ bin/postgres -D ./data --listen_addresses='*'
```

Bonus note: for more convenient options when developping (instead of this easy procedure for installing and just running the system), you can do these bonus steps:
- use `-j8` during the make phase if you have a beefy machine to speed up compilation
- install libreadline dev (fedora package: readline-devel, ubuntu: libreadline-dev) and remove `--without-readline` (this gives you navigability using arrows in the psql client if you use it often to run queries manually to diagnose or debug)
- install zlib dev (fedora pacakge: zlib-devel , ubuntu: zlib1g-dev) and remove `--without-zlib` (this gives you compressed exports if you want to backup your databases..)
- compile auto_explain (cd in the source folder in contrib/auto_explain, run make, make install) and configure it (add `shared_preload_libraries = 'auto_explain'` and
`auto_explain.log_min_duration = 0` at the end postgresql.conf to log every query on the console for example). this requires a restart of postgres.

### Postgres schema setup

```bash
$ bin/psql postgres
$ create database ds;
$ create database directory;
$ create database study;
$ create database actions;
```

Then initialize the schemas for the databases: 
```html
$ \c ds; # and copy https://github.com/gridsuite/dynamic-simulation-server/blob/main/src/main/resources/result.sql content to psql
$ \c directory; # and copy https://github.com/gridsuite/directory-server/blob/main/src/main/resources/schema.sql content to psql
$ \c study; # and copy https://github.com/gridsuite/study-server/blob/master/src/main/resources/study.sql content to psql
$ \c actions; # and copy https://github.com/gridsuite/actions-server/blob/master/src/main/resources/actions.sql content to psql
```

### Minikube and kubectl setup

Download and install [minikube](https://kubernetes.io/fr/docs/tasks/tools/install-minikube/) and [kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/).

Start minikube and activate ingress support:
```bash
$ minikube start --memory 8192
$ minikube addons enable ingress
```

Verify everything is ok with:
```bash
$ minikube status
$ minikube kubectl cluster-info
```

### K8s deployment

Clone deployment repository:
```bash 
$ git clone https://github.com/gridsuite/deployment.git
$ cd deployment
```

Change Cassandra daemon ip address in k8s/overlays/local/cassandra.properties
```properties
cassandra.contact-points=<CASSANDRA_IP>
cassandra.port=9042
```

Change Cassandra daemon ip address in k8s/overlays/local/cassandra.properties
```properties
dbVendor=postgresql
host=<PG_IP>
```

Get you ingress ip, with minikube for example
```bash
$ INGRESS_HOST=`minikube ip`;
$ echo $INGRESS_HOST;
```

Fill config files with the INGRESS_HOST in ./k8s/overlays/local/ :

```
$ cd ./k8s/overlay/local/
$ sed -i -e "s/<INGRESS_HOST>/${INGRESS_HOST}/g" *
```

k8s/overlays/local/gridstudy-app-idpSettings.json :
```json
{
    "authority" : "http://<INGRESS_HOST>/oidc-mock-server/",
    "client_id" : "gridstudy-client",
    "redirect_uri": "http://<INGRESS_HOST>/gridstudy/sign-in-callback",
    "post_logout_redirect_uri" : "http://<INGRESS_HOST>/gridstudy/logout-callback",
    "silent_redirect_uri" : "http://<INGRESS_HOST>/gridstudy/silent-renew-callback",
    "scope" : "openid"
}
```

k8s/overlays/local/gridmerge-app-idpSettings.json
```json
{
    "authority" : "http://<INGRESS_HOST>/oidc-mock-server/",
    "client_id" : "gridmerge-client",
    "redirect_uri": "http://<INGRESS_HOST>/gridmerge/sign-in-callback",
    "post_logout_redirect_uri" : "http://<INGRESS_HOST>/gridmerge/logout-callback",
    "silent_redirect_uri" : "http://<INGRESS_HOST>/gridmerge/silent-renew-callback",
    "scope" : "openid"
}
```

k8s/overlays/local/gridactions-app-idpSettings.json
```json
{
    "authority" : "http://<INGRESS_HOST>/oidc-mock-server/",
    "client_id" : "gridactions-client",
    "redirect_uri": "http://<INGRESS_HOST>/gridactions/sign-in-callback",
    "post_logout_redirect_uri" : "http://<INGRESS_HOST>/gridactions/logout-callback",
    "silent_redirect_uri" : "http://<INGRESS_HOST>/gridactions/silent-renew-callback",
    "scope" : "openid"
}
```

k8s/overlays/local/oidc-mock-server-deployment.yaml :
```yaml
spec:
      containers:
      - name: oidc-mock-server
        image: docker.io/gridsuite/oidc-mock-server:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
        env:
        - name: DEBUG
          value: "oidc-provider:*"
        - name: CLIENT_ID
          value: "gridstudy-client"
        - name: CLIENT_COUNT
          value: 3
        - name: CLIENT_REDIRECT_URI
          value: "http://<INGRESS_HOST>/gridstudy/sign-in-callback"
        - name: CLIENT_LOGOUT_REDIRECT_URI
          value: "http://<INGRESS_HOST>/gridstudy/logout-callback"
        - name: CLIENT_SILENT_REDIRECT_URI
          value: "http://<INGRESS_HOST>/gridstudy/silent-renew-callback"
        - name: CLIENT_ID_2
          value: "gridmerge-client"
        - name: CLIENT_REDIRECT_URI_2
          value: "http://<INGRESS_HOST>/gridmerge/sign-in-callback"
        - name: CLIENT_LOGOUT_REDIRECT_URI_2
          value: "http://<INGRESS_HOST>/gridmerge/logout-callback"
        - name: CLIENT_SILENT_REDIRECT_URI_2
          value: "http://<INGRESS_HOST>/gridmerge/silent-renew-callback"
        - name: CLIENT_ID_3
          value: "gridactions-client"
        - name: CLIENT_REDIRECT_URI_3
          value: "http://<INGRESS_HOST>/gridactions/sign-in-callback"
        - name: CLIENT_LOGOUT_REDIRECT_URI_3
          value: "http://<INGRESS_HOST>/gridactions/logout-callback"
        - name: CLIENT_SILENT_REDIRECT_URI_3
          value: "http://<INGRESS_HOST>/gridactions/silent-renew-callback"
        - name: ISSUER_HOST
          value: "<INGRESS_HOST>"
        - name: ISSUER_PREFIX
          value: "/oidc-mock-server"
      restartPolicy: Always
```

k8s/overlays/local/allowed-issuers.yml
```yaml
allowed-issuers: http://<INGRESS_HOST>/oidc-mock-server
```


Deploy k8s services:
```bash 
$ kubectl apply -k k8s/overlays/local
```

Verify all services and pods have been correctly started:
```bash 
$ kubectl get all
```
You can now access to the application and the swagger UI of all the Spring services:

Applications:
```html
http://<MINIKUBE_IP>/gridstudy-app/
http://<MINIKUBE_IP>/gridmerge-app/
http://<MINIKUBE_IP>/gridactions-app/
```

Gateway 
```html
http://<MINIKUBE_IP>/gateway/
```

Swagger UI:
```html
http://<MINIKUBE_IP>/case-server/swagger-ui.html
http://<MINIKUBE_IP>/cgmes-gl-server/swagger-ui.html
http://<MINIKUBE_IP>/geo-data-server/swagger-ui.html
http://<MINIKUBE_IP>/network-conversion-server/swagger-ui.html
http://<MINIKUBE_IP>/network-store-server/swagger-ui.html
http://<MINIKUBE_IP>/network-map-server/swagger-ui.html
http://<MINIKUBE_IP>/odre-server/swagger-ui.html
http://<MINIKUBE_IP>/single-line-diagram-server/swagger-ui.html
http://<MINIKUBE_IP>/study-server/swagger-ui.html
http://<MINIKUBE_IP>/network-modification-server/swagger-ui.html
http://<MINIKUBE_IP>/loadflow-server/swagger-ui.html
http://<MINIKUBE_IP>/merge-orchestrator-server/swagger-ui.html
http://<MINIKUBE_IP>/cgmes-boundary-server/swagger-ui.html
http://<MINIKUBE_IP>/actions-server/swagger-ui.html
http://<MINIKUBE_IP>/security-analysis-server/swagger-ui.html
http://<MINIKUBE_IP>/config-server/swagger-ui.html
http://<MINIKUBE_IP>/directory-server/swagger-ui.html
```

### Docker compose  deployment
Install the orchestration tool docker-compose then launch the desired profile :

```bash 
$ cd docker-compose/suite
$ docker-compose up
```
```bash 
$ cd docker-compose/study
$ docker-compose up
```
```bash 
$ cd docker-compose/merging
$ docker-compose up
```

```bash 
$ cd docker-compose/actions
$ docker-compose up
```
Note : When using docker-compose for deployment, your machine is accessible from the containers thought the ip adress
`172.17.0.1` so to make the cassandra cluster, running on your machine, accessible from the deployed
containers change the '<YOUR_IP>' of the first section to `172.17.0.1`

You can now access to all applications and swagger UIs of the Spring services of the chosen profile:

Applications:
```html
http://localhost:80 // gridstudy
http://localhost:81 // gridmerge
http://localhost:82 // gridactions
```

Gateway 
```html
http://localhost:9000/
```

Swagger UI:
```html
http://localhost:5000/swagger-ui.html  // case-server
http://localhost:8095/swagger-ui.html  // cgmes-gl-server
http://localhost:8087/swagger-ui.html  // geo-data-server
http://localhost:5003/swagger-ui.html  // network-conversion-server
http://localhost:8080/swagger-ui.html  // network-store-server
http://localhost:5006/swagger-ui.html  // network-map-server
http://localhost:8096/swagger-ui.html  // odre-server
http://localhost:5005/swagger-ui.html  // single-line-diagram-server
http://localhost:5001/swagger-ui.html  // study-server
http://localhost:5007/swagger-ui.html  // network-modification-server
http://localhost:5008/swagger-ui.html  // loadflow-server
http://localhost:5020/swagger-ui.html  // merge-orchestrator-server
http://localhost:5021/swagger-ui.html  // cgmes-boundary-server
http://localhost:5022/swagger-ui.html  // actions-server
http://localhost:5023/swagger-ui.html  // security-analysis-server
http://localhost:5025/swagger-ui.html  // config-server
http://localhost:5026/swagger-ui.html  // directory-server
```
RabbitMQ management UI:
```html
http://localhost:15672
default credentials : 
   - username : guest
   - password : guest
```
Kibana management UI:
```html
http://localhost:5601
```
In order to show documents in the case-server index with Kibana, you must first create the index pattern ('Management' page) : case-server*

In order to use your own versions of Spring services with docker-compose, you have to generate your own Docker images (using jib:dockerBuild Maven goal) and modify the docker-compose.yml to use these images.

Docker image is generated using the following command in the considered service folder:
```bash 
mvn jib:dockerBuild -Djib.to.image=<my_image_name>
```
Once the image has been generated, you have to modify the name of the image to use in docker-compose.yml file, for the considered service:
```bash
services:
...
  my-service:
    image: <my_image_name>:latest
...
```
Now, when using ```docker-compose up```, your custom Docker image will be used. 

