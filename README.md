This is a base Jenkins image with pre-installed plugins and a test job.

Default user credentials: admin@admin

# How to run?
1. Get a fresh VM (tested on Ubuntu 18.04 LTS)
2. Install docker into VM
3. Execute following commands:
```
docker network create jenkins

docker volume create jenkins-docker-certs
docker volume create jenkins-data

docker container run --name jenkins-docker --rm --detach \
  --privileged --network jenkins --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 docker:dind
  
  docker container run --name jenkins-bsa --rm --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  --publish 8080:8080 --publish 50000:50000 bsahub/jenkins-autotests:latest
  ```

## Post install steps:
1. Setup # of executors (default 10) and quiet period (default 5 sec.) - Manage Jenkins -> Configure System