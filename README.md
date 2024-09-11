# GridSuite local deployment

## Local setup

### Databases folders configuration

All data must be stored under a common root directory whose location is defined by the environment variable **$GRIDSUITE_DATABASES**

The following subdirectories must be created with file **mode 777 (rwx)** :
- **cases** : working directory for cases-server
- **postgres** : databases Postgres
- **elasticsearch** : indexes (documents) Elasticsearch
- **init** : data files for initialization

```
$ cd $GRIDSUITE_DATABASES
$ chmod 777 cases postgres elasticsearch init
```

| :warning:  This environment variable must be set and subdirectories created before running any containers with docker-compose ! |
|---------------------------------------------------------------------------------------------------------------------------------|


<a name="data_init"></a>When the postgres container is created, all databases are created automatically as well as the necessary initial data loading (geographical, cgmes boundaries, tsos, lines catalog...).

To do this, you must copy the following files in the init directory (_$GRIDSUITE_DATABASES/init_), **before** creating the postgres container:
- [geo_data_substations.json](https://raw.githubusercontent.com/gridsuite/geo-data/main/src/test/resources/geo_data_substations.json)
- [geo_data_lines.json](https://raw.githubusercontent.com/gridsuite/geo-data/main/src/test/resources/geo_data_lines.json)
- [business_processes.json](https://raw.githubusercontent.com/gridsuite/cgmes-boundary-server/main/src/test/resources/business_processes.json)
- [tsos.json](https://raw.githubusercontent.com/gridsuite/cgmes-boundary-server/main/src/test/resources/tsos.json)
- [lines-catalog.json](https://raw.githubusercontent.com/gridsuite/network-modification-server/main/src/test/resources/lines-catalog.json)

### Clone deployment repository

```bash
$ git clone https://github.com/gridsuite/deployment.git
$ cd deployment
```

## Docker compose deployment

> **Important**
> [Docker Compose v2](https://docs.docker.com/compose/install/standalone/) is mandatory.  
> _See instructions in [sub-section](#installing--updating-docker-compose-to-v2)_


### Application profiles _(alias)_
> [!NOTE]  
> If you want to use profiles other than the ones associated with the folders (`dynamic-mapping`, `merging`, `study`, `suite`, `technical`), you have to use profiles as explained in the [next section](#docker-compose-profiles).

```bash
$ cd docker-compose/suite
$ docker compose up
```
```bash
$ cd docker-compose/study
$ docker compose up
```
```bash
$ cd docker-compose/merging
$ docker compose up
```
```bash
$ cd docker-compose/dynamic-mapping
$ docker compose up
```

__Note__ : When using docker-compose for deployment, your machine is accessible from the containers thought the ip address 172.17.0.1

__Note__ : The containers are accessible from your machine thought the ip address `127.0.0.1` (localhost) or `172.17.0.1` and the corresponding port

__Note__ :
These folders (other than `explicit-profiles`) act now like an alias to `docker compose --project-name grid<name> --profile <folder_name> ...`,
with the difference that they have implicitly a profile active and will be considered like another project stack,
so compose commands will not affect others folders state.

### Docker-compose profiles
This is the preferred development deployment.  
_Everything described in this section is inside the folder `explicit-profiles`._

Here's the summary of the profiles and what services they includes:
| Component \ Service | _(none)_ | merging | study | study-light | dynamic-mapping | dynamic-simulation | suite | import | kibana | pgadmin | metrics |
|---|---|---|---|---|---|---|---|---|---|---|---|
| rabbitmq<br/>postgres<br/>elasticsearch | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| kibana<br/>logstash<br/>socat<br/>logspout | | | | | | | | | ✅ | | |
| pgadmin | | | | | | | | | | ✅ | |
| apps&#8209;metadata&#8209;server<br/>mock&#8209;user&#8209;service<br/>gateway<br/>actions&#8209;server<br/>case&#8209;server<br/>config&#8209;notification&#8209;server<br/>config&#8209;server<br/>filter&#8209;server<br/>loadflow&#8209;server<br/>network&#8209;conversion&#8209;server<br/>network&#8209;store&#8209;server<br/>report&#8209;server<br/>user&#8209;admin&#8209;server | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | | |
| griddyna&#8209;app<br/>dynamic&#8209;mapping&#8209;server | | | | | ✅ | ✅ | ✅ | | | | |
| gridmerge&#8209;app<br/>balances&#8209;adjustment&#8209;server<br/>case&#8209;import&#8209;job<br/>case&#8209;validation&#8209;server<br/>cgmes&#8209;assembling&#8209;job<br/>cgmes&#8209;boundary&#8209;import&#8209;job<br/>cgmes&#8209;boundary&#8209;server<br/>merge&#8209;notification&#8209;server<br/>merge&#8209;orchestrator&#8209;server | | ✅ | | | | | ✅ | | | | |
| gridstudy&#8209;app<br/>dynamic&#8209;simulation&#8209;server<br/>timeseries&#8209;server | | | ✅ | | | ✅ | ✅ | | | | |
| cgmes&#8209;gl&#8209;server<br/>odre&#8209;server<br/>security&#8209;analysis&#8209;server<br/>sensitivity&#8209;analysis&#8209;server<br/>shortcircuit&#8209;server<br/>voltage&#8209;init&#8209;server<br/>gridadmin&#8209;app | | | ✅ | | | | ✅ | | | | |
| directory&#8209;notification&#8209;server<br/>directory&#8209;server<br/>explore&#8209;server<br/>geo&#8209;data&#8209;server<br/>gridexplore&#8209;app<br/>network&#8209;map&#8209;server<br/>network&#8209;modification&#8209;server<br/>single&#8209;line&#8209;diagram&#8209;server<br/>study&#8209;notification&#8209;server<br/>study&#8209;server | | | ✅ | ✅ | | ✅ | ✅ | | | | |
| case&#8209;import&#8209;server | | | | | | | | ✅ | | | |
| grafana<br/>prometheus | | | | | | | | | | | ✅ |

To use a profile, you use:
```shell
$ cd docker-compose/explicit-profiles
$ docker compose --profile suite <cmd>
```

You can also combine multiple profiles:
```shell
$ docker compose --profile study --profile dynamic-mapping <cmd>
```

> [!IMPORTANT]  
> The `--profile` argument isn't always mandatory with some commands:
>   * With the commands `up` & `down`, services/container who belongs to at least one profile can't be accessed if the profile isn't specified.
>     For example `docker compose up study-server` would not work because the profile `study` isn't passed in the CLI.
>     The correct CLI would be `docker compose --profile study up study-server`.
>   * With the commands `start`, `stop`, `restart`, the `--profile ...` has no effect because theses commands affect the containers already created by a previous `up` command.

To change the running profile('s) without `down`&`up` everything (for example you have `up` the profile `suite` and you want now use the profile `study`), you can instead `stop` & `up`:
```shell
# previously: docker compose --profile suite up -d
$ docker compose --profile suite stop
$ docker compose --profile study up -d
```

In case you want to do a `down` for everything, an `all` profile exist to simplify :
```shell
$ docker compose --profile all down
```

If you still have a container existing in the project, you will have this message during the `down`:
```
$ docker compose down
[+] Running 2/1
 ✔ Container abc-server             Removed                      10.6s
 ! Network gridsuite_default        Resource is still in use     0.0s
```


### Technical profile

This profile allows you to launch only the technical services : postgres, elasticsearch, rabbitmq, ...

| Software      | Version used |
|---------------|--------------|
| Postgres      | 14.9         |
| RabbitMQ      | latest       |
| Elasticsearch | 7.9.3        |
| Grafana       | latest       |
| Prometheus    | latest       |


It is used for k8s deployment with Minikube.

```bash
$ cd docker-compose/technical
$ docker compose up
```

### Update docker-compose images
To synchronize with the latest images for a docker-compose profile, you need to :
- delete the containers
```bash
$ docker compose down
```
- get latest images
```bash
$ docker compose pull
```
- recreate containers
```bash
$ docker compose up
```

- remove old images
```bash
$ docker image prune -f
```

### Applications and Swagger URLs

You can now access to all applications and swagger UIs of the Spring services of the chosen profile:

Applications:
```html
http://localhost:80 // gridexplore
http://localhost:81 // gridmerge
http://localhost:82 // gridadmin
http://localhost:83 // griddyna
http://localhost:84 // gridstudy
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
http://localhost:5029/swagger-ui.html  // explore-server
http://localhost:5036/swagger-ui.html  // dynamic-mapping-server
http://localhost:5032/swagger-ui.html  // dynamic-simulation-server
http://localhost:5027/swagger-ui.html  // filter-server
http://localhost:5010/swagger-ui.html  // balances-adjustment-server
http://localhost:5011/swagger-ui.html  // case-validation-server
http://localhost:5033/swagger-ui.html  // user-admin-server
http://localhost:5030/swagger-ui.html  // sensitivity-analysis-server
http://localhost:5031/swagger-ui.html  // shortcircuit-server
http://localhost:5037/swagger-ui.html  // timeseries-server
http://localhost:5038/swagger-ui.html  // voltage-init-server
http://localhost:5039/swagger-ui.html  // case-import-server
```

### RabbitMQ console

RabbitMQ management UI:

```html
http://localhost:15672
default credentials :
   - username : guest
   - password : guest
```

### PgAdmin for PostgreSQL administration

PgAdmin UI:

```html
http://localhost:12080/login
default credentials :
   - username : admin@localhost.com
   - password : admin
```

To connect to the PostgreSQL database, the postgres container must be up.
Then, you can add a new server with the following configurations :

```html
Host name/address : postgres
Port : 5432
Maintenance database : postgres
Username : postgres
Password : postgres
```

### Kibana console for Elasticsearch

Kibana management UI:
```html
http://localhost:5601
```
In order to show documents in the case-server index with Kibana, you must first create the index pattern ('Management' page) : case-server*

### Grafana console for metrics
Grafana UI:
```html
http://localhost:7000
```


### Installing / Updating docker-compose to v2
[Docker compose v2](https://github.com/docker/compose) is necessary to be able to use this compose project which uses [profiles feature](https://docs.docker.com/compose/profiles/).  
If possible, prefer to install it with your package manager if you are on a Unix system.

> [!NOTE]  
> You need a client (docker-cli) of ~v19~ v20 at least to have the system of cli-plugins.
> It isn't necessary to update your Docker engine or client else.

You can install Docker Compose v2 with these commands, as instructed in [the doc](https://docs.docker.com/compose/install/linux/#install-the-plugin-manually) and the [migration guide](https://docs.docker.com/compose/migrate/):
```shell
curl -LR --create-dirs -o $HOME/.local/bin/docker-compose https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64
#wget -x -O $HOME/.local/bin/docker-compose https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64
chmod +x $HOME/.local/bin/docker-compose
mkdir -p $HOME/.docker/cli-plugins
ln -s $HOME/.local/bin/docker-compose $HOME/.docker/cli-plugins/docker-compose
docker compose version
```
You must get this output from docker compose now:
> Docker Compose version v2.xx.x

> [!IMPORTANT]  
> The commands shown will install the plugin user-side, so you don't need to remove your old docker-compose v1 if it is installed system-wide.


## k8s deployment with Minikube

### Minikube and kubectl setup

This setup is heavyweight and matches a realworld deployment. It is useful to reproduce realworld kubernetes effects and features. In most cases, the lighter docker-compose deployment is preferred.

Download the recommended version of minikube and kubectl :

| Software | Version recommendation | Last supported version | Link                                                                                                  |
|----------|------------------------|------------------------|-------------------------------------------------------------------------------------------------------|
| kubectl  | 1.21+                  | 1.27.4                 | [Download](https://storage.googleapis.com/kubernetes-release/release/v1.27.4/bin/linux/amd64/kubectl) |
| minikube | 1.21+                  | 1.31.2                 | [Download](https://storage.googleapis.com/minikube/releases/v1.31.2/minikube-linux-amd64)             |


install [minikube](https://kubernetes.io/fr/docs/tasks/tools/install-minikube/#installez-minikube-par-t%C3%A9l%C3%A9chargement-direct) and [kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/#installer-le-binaire-de-kubectl-avec-curl-sur-linux) following instructions for binaries download installation.

__Notes__: We require minikube 1.21+ for host.minikube.internal support inside containers (if you want to use an older minikube, replace host.minikube.internal with the IP of your host).

__Notes__: Minikube 1.32.0 has been tested and is not working on our stack, so please use version 1.31.2 or below.

Start minikube :
```bash
$ minikube start --memory 24g --cpus=4
```

To specify the driver used by minikube and use specific version of kubernetes you could alternatively use :
```bash
$ minikube start --memory 24g --cpus=4 --driver=virtualbox --kubernetes-version=1.22.3
```

__Notes__: With last version of minikube, *docker* is the default driver (was *virtualbox* before) which could forbid memory definition depending of your user privilegies.

see [kubernetes-version param doc](https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64) for versions support.

Activate ingress support:
```bash
$ minikube addons enable ingress
```

Verify everything is ok with:
```bash
$ minikube status
$ minikube kubectl cluster-info
```

### Minikube deployment

Get you ingress ip
```bash
$ INGRESS_HOST=`minikube ip`
$ echo $INGRESS_HOST
```

Fill config files with the INGRESS_HOST in k8s/live/local/ :
```bash
$ find k8s/live/local/ -type f | xargs sed -i -e "s/<INGRESS_HOST>/${INGRESS_HOST}/g"
```

Optionally, give an ssh access to the case importing cronjobs by providing your username and your password (or create a dedicated user for this if you want):
The import jobs connect through ssh to your machine and automatically import files from the $HOME/opde and $HOME/boundaries
```bash
$ find k8s/live/local/ -type f | xargs sed -i -e 's/<USERNAME>/YOURUSERNAME/g'
$ find k8s/live/local/ -type f | xargs sed -i -e 's/<PASSWORD>/YOURPASSWORD/g'
```

Start technical services with the docker-compose technical profile  :
```bash
$ cd docker-compose/technical
$ docker compose up -d
```

Deploy k8s services:
```bash
$ kubectl apply -k k8s/live/local
```

Verify all services and pods have been correctly started:
```bash
$ kubectl get all
```
You can now access to the application and the swagger UI of all the Spring services:

Applications:
```html
http://<INGRESS_HOST>/gridstudy/
http://<INGRESS_HOST>/gridmerge/
http://<INGRESS_HOST>/griddyna/
http://<INGRESS_HOST>/gridexplore/
http://<INGRESS_HOST>/gridadmin/
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
http://<INGRESS_HOST>/user-admin-server/swagger-ui.html
http://<INGRESS_HOST>/sensitivity-analysis-server/swagger-ui.html
http://<INGRESS_HOST>/shortcircuit-server/swagger-ui.html
http://<INGRESS_HOST>/timeseries-server/swagger-ui.html
http://<INGRESS_HOST>/voltage-init-server/swagger-ui.html
http://<INGRESS_HOST>/case-import-server/swagger-ui.html
```

## How to use a local docker image into Minikube?

Build and load a local image into Minikube:
```bash
$ mvn clean install jib:dockerBuild -Djib.to.image=local/<pod>
$ minikube image load local/<pod>
```
__Notes__: If you have issues, you can build with the Docker deamon bundled in the minikube to directly have access to the image inside the minikube, [instructions here](https://minikube.sigs.k8s.io/docs/handbook/pushing/)

Then add it to your deployment before (re)deploy:
```bash
$ vi <pod>-deployment.yaml
+  image: docker.io/local/<pod>:latest
```

Check the pod has started with your local image:
```bash
$ kubectl describe pod <pod-instance> | grep "Image:"
  Image:         docker.io/local/<pod>:latest
```

## Multiple environments with customized prefixes

To deploy multiple environments we can use customized prefixed databases (Postgres), queues (rabbitMq) and indexes (elasticsearch).

You must follow those steps:
1. Edit the `docker-compose/.env` file and  specify the prefix by defining the `DATABASE_PREFIX_NAME` property
```yaml
DATABASE_PREFIX_NAME=dev_
```
2. Edit the `k8s/base/config/common-application.yml` file and specify the prefix by defining the `environement` property
```yaml
powsybl-ws:
  environment: dev_
```

:warning: do not forget to include underscore '_'

After this configuration :
* every services which use a Postgres database will call to **dev_**`{dbName}` database.
* every services which provide or read a rabbitMq queue will call to **dev_**`{queueName}` queue.
* every services which use a elasticsearch index will call to **dev_**`{indexName}` index.


## Databases creation and data initialization

Considering databases are created automatically as well as the necessary initial data (geographical, cgmes boundaries, tsos, ...), the following part concerns only the databases recreation and/or the update of the initial data.
All actions can be done from a docker-compose profile.

### Databases creation

With a terminal, go to the docker directory where you ran the `docker compose up -d` command.

Make sure the `postgres` service is up with the `docker compose ps | grep postgres` command.
```bash
$ docker compose exec postgres /create-postgres-databases.sh
```

### Data initialization

First update the data files in the directory `$GRIDSUITE_DATABASES/init`

[See the initial data loading section for more information.](#data_init)

Alternatively, you can do this :

With a terminal, go to the docker directory where you ran the `docker compose up -d` command.

Make sure the `postgres`, `odre-server`, `geo-data-server` and `network-modification-server` services are up with the `docker compose ps` command.
```bash
$ docker compose exec postgres /init-geo-data.sh
$ docker compose exec postgres /init-lines-catalog.sh
$ docker compose exec postgres /init-merging-data.sh
```

**Note**: For RTE geographic data (lines and substations), alternately, you can use the `odre-server` swagger UI (see the URL above) to automaticaly download and import those data in your database. You have to execute those REST requests :

* .../substations
* .../lines

Be sure to have at least `odre-server` and `geo-data-server` containers running.

## Working with Spring services

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
Now, when using ```docker compose up```, your custom Docker image will be used.

