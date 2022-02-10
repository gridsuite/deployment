# GridSuite deployment

## Gridsuite local install

### Cassandra install

Download the recommended version of Cassandra :

|Distribution| Version recommendation |Version  | Link|
--- | --- | --- | ---
|Fedora|3.x|3.11.10|[Download](https://www.apache.org/dyn/closer.lua/cassandra/3.11.10/apache-cassandra-3.11.10-bin.tar.gz)|
|Ubuntu|4.x|4.0.0|[Download](https://www.apache.org/dyn/closer.lua/cassandra/4.0.0/apache-cassandra-4.0.0-bin.tar.gz)|



In order to be accessible from k8s cluster, Cassandra has to be bind to one the ip address of the machine.  The following variables have to be modified in conf/cassandra.yaml before starting the Cassandra daemon.

```yaml
seed_provider:
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
      parameters:
          - seeds: "<YOUR_IP>"

listen_address: "<YOUR_IP>"

rpc_address: "0.0.0.0"

broadcast_rpc_address: "<YOUR_IP>"

enable_materialized_views: true
```

During development, to reduce ram usage, it is recommended to configure the Xmx and Xms in conf/jvm.options (v3.x) or conf/jvm-server.options (v4.x). Uncomment the Xmx and Xms lines, a good value to start with is `-Xms2G` and `-Xmx2G`.

To start the cassandra server: 

``` 
$ cd /path/to/cassandra/folder`
$ bin/cassandra -f`
```
### Cassandra schema setup

__Cassandra schema creation__

First, you must connect to cassandra database server with cqlsh client
```bash
$ bin/cqlsh
```
---
__Use default keyspace names__

To create Grid Suite keyspaces in a single node cluster:
```cql
CREATE KEYSPACE IF NOT EXISTS iidm WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS geo_data WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1};
CREATE KEYSPACE IF NOT EXISTS cgmes_boundary WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS cgmes_assembling WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS import_history WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
```
----

__Or use custom keyspace names__

To create Grid Suite custom keyspaces in a single node cluster:

```cql
CREATE KEYSPACE IF NOT EXISTS <KEYSPACE_NAME_NETWORK_STORE> WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS <KEYSPACE_NAME_GEO_DATA> WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1};
CREATE KEYSPACE IF NOT EXISTS <KEYSPACE_NAME_CGMES_BOUNDARY> WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS <KEYSPACE_NAME_CGMES_ASSEMBLING> WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS <KEYSPACE_NAME_CASE_IMPORT> WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
```

Then you must configure keyspace names in those files :
- k8s/base/config/network-store-server-application.yml
- k8s/base/config/geo-data-server-application.yml
- k8s/base/config/cgmes-boundary-server-application.yml
```properties
cassandra-keyspace: <CUSTOM_KEYSPACE_NAME>
```
and for 
- docker-compose/merging/cgmes-assembling-job/cgmes-assembling-job-config.yml
- docker-compose/case-import-job/case-import-job-config.yml
```properties
cassandra:
    ...
    keyspace-name: <CUSTOM_KEYSPACE_NAME>
```
----
#### __Cassandra schema initialization__

Then you must initialize each keyspace, following those instructions :
First connect to corresponding keyspace
```bash
$ bin/cqlsh -k <KEYSPACE_NAME>
```
Then copy/paste the corresponding following files content to cqlsh shell:

- connect to <KEYSPACE_NAME_NETWORK_STORE> then copy/paste : [iidm.cql](https://raw.githubusercontent.com/powsybl/powsybl-network-store/main/network-store-server/src/main/resources/iidm.cql)
- connect to <KEYSPACE_NAME_GEO_DATA> then copy/paste : [geo_data.cql](https://raw.githubusercontent.com/powsybl/powsybl-geo-data/main/geo-data-server/src/main/resources/geo_data.cql)
- connect to <KEYSPACE_NAME_CGMES_BOUNDARY> then copy/paste : [cgmes_boundary.cql](https://raw.githubusercontent.com/gridsuite/cgmes-boundary-server/main/src/main/resources/cgmes_boundary.cql)    
- connect to <KEYSPACE_NAME_CGMES_ASSEMBLING> then copy/paste : [cgmes_assembling.cql](https://raw.githubusercontent.com/gridsuite/cgmes-assembling-job/main/src/main/resources/cgmes_assembling.cql)    
- connect to <KEYSPACE_NAME_CASE_IMPORT> then copy/paste : [import_history.cql](https://raw.githubusercontent.com/gridsuite/case-import-job/main/src/main/resources/import_history.cql)

### PostgresSql install

Postgresql is not as easy as cassandra to download and just run in its folder, but it's almost as easy. 
To get a postgresql folder where you can just run postgresql, you have to compile from source (very easy because there 
are almost no compilation dependencies) and run an init command once. If you prefer other methods, 
feel free to install and run postgresql with your system package manager or with a dedicate docker container.

**Postgres local install from code sources:**

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
$ create database networkmodifications;
$ create database merge_orchestrator;
$ create database dynamicmappings;
$ create database filters;
$ create database report;
$ create database config;
$ create database sa;
```

The database schemas are handled by the microservices themselves using liquibase.

### Cases folders configuration

| :warning:  BEFORE running any containers!   |
|---------------------------------------------|

Create a `~/cases/` folder in your /home/user root folder.
then assign rwx credentials to it.
```
chmod 777 cases
```
This is a working directory for cases-server.

### Minikube and kubectl setup

This setup is heavyweight and matches a realworld deployment. It is useful to reproduce realworld kubernetes effects and features. In most cases, the lighter docker-compose deployment is preferred.

Download the recommended version of minikube and kubectl :

|Software| Version recommendation |Last Version  | Link|
--- | --- | --- | ---
|kubectl|1.18.12|1.22.X ( :warning: not supported yet)|[Download](https://storage.googleapis.com/kubernetes-release/release/v1.18.12/bin/linux/amd64/kubectl)|
|minikube|1.21+|1.24.0|[Download](https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64)|


install [minikube](https://kubernetes.io/fr/docs/tasks/tools/install-minikube/#installez-minikube-par-t%C3%A9l%C3%A9chargement-direct) and [kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/#installer-le-binaire-de-kubectl-avec-curl-sur-linux) following instructions for binaries download installation.

__Notes__: We require minikube 1.21+ for host.minikube.internal support inside containers (if you want to use an older minikube, replace host.minikube.internal with the IP of your host).

Start minikube and activate ingress support:
```bash
$ minikube start --memory 24g --cpus=4 
$ minikube addons enable ingress
```

To specify the driver used by minikube and use specific version of kubernetes you could alternatively use :
```bash
$ minikube start --memory 24g --cpus=4 --driver=virtualbox --kubernetes-version=$KUBECTL_VERSION
$ minikube addons enable ingress
```

__Notes__: With last version of minikube, *docker* is the default driver (was *virtualbox* before) which could forbid memory definition depending of your user privilegies.

see [kubernetes-version param doc](https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64) for versions support.

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

Get you ingress ip
```bash
$ INGRESS_HOST=`minikube ip`
$ echo $INGRESS_HOST
```

Fill config files with the INGRESS_HOST in k8s/overlays/local/ :
```bash
$ sed -i -e "s/<INGRESS_HOST>/${INGRESS_HOST}/g" k8s/overlays/local/*
```

Optionally, give an ssh access to the case importing cronjobs by providing your username and your password (or create a dedicated user for this if you want):
The import jobs connect through ssh to your machine and automatically import files from the $HOME/opde and $HOME/boundaries
```bash
$ sed -i -e 's/<USERNAME>/YOURUSERNAME/g' k8s/overlays/local/*
$ sed -i -e 's/<PASSWORD>/YOURPASSWORD/g' k8s/overlays/local/*
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
http://<INGRESS_HOST>/gridstudy-app/
http://<INGRESS_HOST>/gridmerge-app/
http://<INGRESS_HOST>/griddyna-app/
http://<INGRESS_HOST>/gridexplore-app/
```

Swagger UI:
```html
http://<INGRESS_HOST>/case-server/swagger-ui.html
http://<INGRESS_HOST>/cgmes-gl-server/swagger-ui.html
http://<INGRESS_HOST>/geo-data-server/swagger-ui.html
http://<INGRESS_HOST>/network-conversion-server/swagger-ui.html
http://<INGRESS_HOST>/network-store-server/swagger-ui.html
http://<INGRESS_HOST>/network-map-server/swagger-ui.html
http://<INGRESS_HOST>/odre-server/swagger-ui.html
http://<INGRESS_HOST>/single-line-diagram-server/swagger-ui.html
http://<INGRESS_HOST>/study-server/swagger-ui.html
http://<INGRESS_HOST>/network-modification-server/swagger-ui.html
http://<INGRESS_HOST>/loadflow-server/swagger-ui.html
http://<INGRESS_HOST>/merge-orchestrator-server/swagger-ui.html
http://<INGRESS_HOST>/cgmes-boundary-server/swagger-ui.html
http://<INGRESS_HOST>/actions-server/swagger-ui.html
http://<INGRESS_HOST>/security-analysis-server/swagger-ui.html
http://<INGRESS_HOST>/config-server/swagger-ui.html
http://<INGRESS_HOST>/directory-server/swagger-ui.html
http://<INGRESS_HOST>/balances-adjustment-server/swagger-ui.html
http://<INGRESS_HOST>/case-validation-server/swagger-ui.html
http://<INGRESS_HOST>/dynamic-simulation-server/swagger-ui.html
http://<INGRESS_HOST>/filter-server/swagger-ui.html 
http://<INGRESS_HOST>/report-server/swagger-ui.html
```

### Docker compose  deployment

This is the preferred development deployment.
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
$ cd docker-compose/dynamic-mapping
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
http://localhost:83 // griddyna
http://localhost:84 // gridexplore
```

Swagger UI:
```html
http://localhost:5000/swagger-ui.html  // case-server
http://localhost:8095/swagger-ui.html  // cgmes-gl-server
http://localhost:8087/swagger-ui.html  // geo-data-server
http://localhost:5003/swagger-ui.html  // network-conversion-server
http://localhost:8080/swagger-ui.html  // network-store-server
http://localhost:5006/swagger-ui.html  // network-map-server
http://localhost:8090/swagger-ui.html  // odre-server
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
http://localhost:5028/swagger-ui.html  // report-server
http://localhost:5036/swagger-ui.html  // dynamic-mapping-server
http://localhost:5032/swagger-ui.html  // dynamic-simulation-server
http://localhost:5027/swagger-ui.html  // filter-server
http://localhost:5010/swagger-ui.html  // balances-adjustment-server
http://localhost:5011/swagger-ui.html  // case-validation-server
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

### Multiple environments with customized prefixes

To deploy multiple environments we can use customized prefixed databases (Postgres), keyspaces (Cassandra), queues (rabbitMq) and indexes (elasticsearch).    

You must follow those steps:
1. [Postgres schema setup](#postgres-schema-setup) with prefixed database names
1. [Cassandra schema setup](#cassandra-schema-setup) with prefixed keyspace names.
1. Edit the common-application.yaml file concerned by your deployment.

**example**: For a Azure developpement deployment we would like to use a prefix then we edit `k8s/overlays/azure-dev/common-application.yml` by defining an `environement` name.     
( :warning: do not forget to include underscore '_')

```yaml
powsybl-ws:
  environment: dev_
```

After this configuration :
* every services which use a Postgres database will call to **dev_**`{dbName}` database.
* every services which use a Cassandra keyspace will call to **dev_**`{keyspaceName}` keyspace.
* every services which provide or read a rabbitMq queue will call to **dev_**`{queueName}` queue.
* every services which use a elasticsearch index will call to **dev_**`{indexName}` index.

**Note** : To customize a docker-compose deployment please edit the following file :    
`k8s/base/config/common-application.yml`

### RTE Geographical data importation

To populate the geo-data-server with RTE geographic lines and substations data, you must use the `odre-server` swagger UI (see the URL above) to automaticaly download and import those data in your database. Both REST requests must be executed.

**Note**: Be sure to have at least `odre-server` and `geo-data-server` containers running.




### Working with Spring services

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

