# GridSuite deployment

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
https://github.com/gridsuite/study-server/blob/master/src/main/resources/study.cql
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
git clone https://github.com/gridsuite/deployment.git
cd deployment
```

Change Cassandra daemon ip address in k8s/overlays/local/cassandra.properties
```properties
cassandra.contact-points: "<YOUR_IP>"
cassandra.port: 9042
```

```bash
MINIKUBE_IP=`minikube ip`;
echo $MINIKUBE_IP;
```
Fill config files with the MINIKUBE_IP :

k8s/overlays/local/idpSettings.json :
```properties
{
    "authority" : "http://<TO COMPLETE>/oidc-mock-server/",
    "client_id" : "my-client",
    "redirect_uri": "http://<TO COMPLETE>/study-app/sign-in-callback",
    "post_logout_redirect_uri" : "http://<TO COMPLETE>/study-app/logout-callback",
    "silent_redirect_uri" : "http://<TO COMPLETE>/study-app/silent-renew-callback",
    "scope" : "openid"
}
```

k8s/overlays/local/oidc-mock-server-deployment.yaml :
```properties
spec:
      containers:
      - name: oidc-mock-server
        image: docker.io/gridsuite/oidc-mock-server:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
        env:
        - name: DEBUG
          value: "oidc-provider:*"
        - name: CLIENT_ID
          value: "my-client"
        - name: CLIENT_REDIRECT_URI
          value: "http://<TO COMPLETE>/study-app/sign-in-callback"
        - name: CLIENT_LOGOUT_REDIRECT_URI
          value: "http://<TO COMPLETE>/study-app/logout-callback"
        - name: CLIENT_SILENT_REDIRECT_URI
          value: "http://<TO COMPLETE>/study-app/silent-renew-callback"
        - name: ISSUER_HOST
          value: "<TO COMPLETE>"
        - name: ISSUER_PREFIX
          value: "/oidc-mock-server"
      restartPolicy: Always
```

k8s/overlays/local/allowed-issuers.yml
```properties
allowed-issuers: http://<TO COMPLETE>/oidc-mock-server
```


Deploy k8s services:
```bash 
kubectl apply -k k8s/overlays/local
```

Verify all services and pods have been correctly started:
```bash 
kubectl get all
```
You can now access to the application and the swagger UI of all the Spring services:
Application:
```html
http://<MINIKUBE_IP>/study-app/
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

```

### Docker compose  deployment
Install the orchestration tool docker-compose then: 
```bash 
cd docker-compose/
docker-compose up
```
Note : When using docker-compose for deployment, your machine is accessible from the containers thought the ip adress
`172.17.0.1` so to make the cassandra cluster, running on your machine, accessible from the deployed
containers change the '<YOUR_IP>' of the first section to `172.17.0.1`

You can now access to the application and the swagger UI of all the Spring services:

Application:
```html
http://localhost
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

```
RabbitMQ management UI (guest/guest) :
```html
http://localhost:15672
```

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

