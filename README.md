# GridSuite deployment

## Gridsuite local install

### Cassandra install

Download the recommended version of Cassandra :

|Distribution| Version recommendation |Version  | Link|
--- | --- | --- | ---
|Fedora|3.x|3.11.10|[Download](https://www.apache.org/dyn/closer.lua/cassandra/3.11.10/apache-cassandra-3.11.10-bin.tar.gz)|
|Ubuntu|4.x|4.0-rc2|[Download](https://www.apache.org/dyn/closer.lua/cassandra/4.0-rc2/apache-cassandra-4.0-rc2-bin.tar.gz)|



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

During development, to reduce ram usage, it is recommended to configure the Xmx and Xms in conf/jvm.options. Uncomment the Xmx and Xms lines, a good value to start with is `-Xms2G` and `-Xmx2G`.

To start the cassandra server: 

``` 
$ cd /path/to/cassandra/folder`
$ bin/cassandra -f`
```
### Cassandra schema setup

```bash
$ bin/cqlsh
```

To create keyspaces in a single node cluster:

```cql
CREATE KEYSPACE IF NOT EXISTS <KEYSPACE_NAME_NETWORK_STORE> WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS <KEYSPACE_NAME_GEO_DATA> WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1};
CREATE KEYSPACE IF NOT EXISTS cgmes_boundary WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS cgmes_assembling WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS sa WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS config WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1};
```

Then (for network store cassandra database) :
```bash
$ bin/cqlsh -k <KEYSPACE_NAME_NETWORK_STORE>
```
Copy paste following files content to cqlsh shell:
[iidm.cql](https://raw.githubusercontent.com/powsybl/powsybl-network-store/master/network-store-server/src/main/resources/iidm.cql)

Change Cassandra keyspace name in k8s/base/config/network-store-server-application.yml
```properties
cassandra-keyspace: <KEYSPACE_NAME_NETWORK_STORE>
```


Then (for geo-data cassandra database) :
```bash
$ bin/cqlsh -k <KEYSPACE_NAME_GEO_DATA>
```
Copy paste following files content to cqlsh shell:
[geo_data.cql](https://raw.githubusercontent.com/powsybl/powsybl-geo-data/master/geo-data-server/src/main/resources/geo_data.cql)

Change Cassandra keyspace name in k8s/base/config/geo-data-server-application.yml
```properties
cassandra-keyspace: <KEYSPACE_NAME_GEO_DATA>
```


Then (for other cassandra databases) :
```bash
$ bin/cqlsh
```
Copy/paste following files content to cqlsh shell:

[cgmes_boundary.cql](https://raw.githubusercontent.com/gridsuite/cgmes-boundary-server/master/src/main/resources/cgmes_boundary.cql)    
[cgmes_assembling.cql](https://raw.githubusercontent.com/gridsuite/cgmes-assembling-job/master/src/main/resources/cgmes_assembling.cql)    
[sa.cql](https://raw.githubusercontent.com/gridsuite/security-analysis-server/master/src/main/resources/sa.cql)    
[config.cql](https://raw.githubusercontent.com/gridsuite/config-server/master/src/main/resources/config.cql)    

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
```

Then initialize the schemas for the databases: 


`$ \c ds;` then copy/paste [result.sql](https://raw.githubusercontent.com/gridsuite/dynamic-simulation-server/main/src/main/resources/result.sql) content to psql    
`$ \c directory;` then copy/paste [directory.sql](https://raw.githubusercontent.com/gridsuite/directory-server/main/src/main/resources/directory.sql) content to psql   
`$ \c study;` then copy/paste [study.sql](https://raw.githubusercontent.com/gridsuite/study-server/master/src/main/resources/study.sql) content to psql   
`$ \c actions;` then copy/paste [actions.sql](https://raw.githubusercontent.com/gridsuite/actions-server/master/src/main/resources/actions.sql) content to psql   
`$ \c networkmodifications;` then copy/paste [network-modification.sql](https://raw.githubusercontent.com/gridsuite/network-modification-server/master/src/main/resources/network-modification.sql) content to psql   
`$ \c merge_orchestrator;` then copy/paste [merge_orchestrator.sql](https://raw.githubusercontent.com/gridsuite/merge-orchestrator-server/master/src/main/resources/merge_orchestrator.sql) content to psql   
`$ \c dynamicmappings;` then copy/paste [mappings.sql](https://raw.githubusercontent.com/gridsuite/dynamic-mapping-server/master/src/main/resources/mappings.sql) and  [IEEE14Models.sql](https://raw.githubusercontent.com/gridsuite/dynamic-mapping-server/master/src/main/resources/IEEE14Models.sql)content to psql   
`$ \c filters;` then copy/paste [filter.sql](https://raw.githubusercontent.com/gridsuite/filter-server/master/src/main/resources/filter.sql) content to psql   
`$ \c report;` then copy/paste [report.sql](https://raw.githubusercontent.com/gridsuite/report-server/master/src/main/resources/report.sql) content to psql   

### Cases folders configuration

The case-server needs to use an accessible `cases` folder in your /home/user root folder

If a folder already exists please check your credentials on it.
To overwrite this folder,
* rename it -> `cases` to `cases_old`
* then create a new folder `cases` and assign it some rights with

```
chmod 777 cases
```
* after the case-server launch this folder must contain 2 subfolders `public` and `private`. No need to change rights on thoses folders.


### Minikube and kubectl setup

This setup is heavyweight and matches a realworld deployment. It is useful to reproduce realworld kubernetes effects and features. In most cases, the lighter docker-compose deployment is preferred.
Download and install [minikube](https://kubernetes.io/fr/docs/tasks/tools/install-minikube/) and [kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/).
We require minikube 1.21+ for host.minikube.internal support inside containers (if you want to use an older minikube, replace host.minikube.internal with the IP of your host).

Start minikube and activate ingress support:
```bash
$ minikube start --memory 24g --cpus=4
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
http://<MINIKUBE_IP>/gridstudy-app/
http://<MINIKUBE_IP>/gridmerge-app/
http://<MINIKUBE_IP>/gridactions-app/
http://<MINIKUBE_IP>/griddyna-app/
http://<MINIKUBE_IP>/gridexplore-app/
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
http://<MINIKUBE_IP>/balances-adjustment-server/swagger-ui.html
http://<MINIKUBE_IP>/case-validation-server/swagger-ui.html
http://<MINIKUBE_IP>/dynamic-simulation-server/swagger-ui.html
http://<MINIKUBE_IP>/filter-server/swagger-ui.html 
http://<MINIKUBE_IP>/report-server/swagger-ui.html
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
$ cd docker-compose/actions
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
http://localhost:82 // gridactions
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

