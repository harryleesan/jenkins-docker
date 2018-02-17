# Jenkins in Docker
### Author: Harry Lee

## What's inside?
- `docker`
- `docker-compose`
- `aws-cli`


## Usage

### TL;DR

**Using** `docker-compose`:
```bash
docker-compose up -d --build
```

**Not using** `docker-compose`:
```bash
docker build -t halosan/jenkins:latest .
docker volume create jenkins_home
docker run -d -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  -v $(pwd)/aws:/var/jenkins_home/.aws:ro \
  --name jenkins \
  --restart always \
  halosan/jenkins:latest
```

After the container has started, the initial **admin** password can be obtained
by:
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```


### Docker
To run `docker` inside of our Jenkins container (_docker-in-docker_), we are
utilizing the _docker-sidecar_ method by
mounting the host docker socket into the Jenkins container.

```bash
docker run \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name jenkins \
  halosan/jenkins:latest
```


### Persist
To persist Jenkins data and configurations, read the
[Official Doc](https://github.com/jenkinsci/docker/blob/master/README.md).
The official doc recommends using a _volume container_ to persist data. A host
directory can also be used, but that requires some permission tweaking to the
host directory.

```bash
docker run -p 8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins \
  halosan/jenkins:latest
```

This creates a _data volume_ that will be the persistence storage for the Jenkins server.
To remove the volume:

```bash
docker volume rm jenkins_home
```


### AWS Credentials
To allow **AWS CLI** in the container access to your AWS resources, in the `aws`
folder enter your aws credentials in the `config` and `credentails` files.

Alternatively, you can mount your own `~/.aws` folder into
`/var/jenkins_home/.aws`.


### Workspace issue workaround
This issue only applies if you are building a pipeline using the `docker`
plugin.
Executing `sh` in the docker container through _docker.inside_ in the
Jenkinsfile through the
mounted docker socket actually means that you are using the workspace on the
host. This means that the directory needs to exist in the host, or else you will
get  '`/jenkins-log.txt: Directory nonexistent`' error.

#### [Resolution](https://github.com/jenkinsci/docker/issues/626)
1. Create a directory on the host that will be used as the workspace. e.g.
   _/var/jenkins_workspaces_ and `chmod -R 777` the directory.
2. Mount this directory as a **bind volume** to the Jenkins container at the
   **exact same directory in the container**.
3. This will be the workspace that is used in your **Jenkinsfile**.
    - Wrap your commands in the custom workspace:
    ```groovy
      ws("/var/jenkins_workspaces/helloworld"){
      YOUR STAGES

      docker.image("x").inside("-u 0:0") {
      }
    }
    ```


## Gotchas

If you are running docker on **MacOS**, the _jenkins_ user in the container will
not have permission to access docker on the host. A work around for this
(security risk) is to add _jenkins_ user to the _root_ group.

```bash
docker exec -t --user root jenkins sh -c "usermod -aG root jenkins"
```

For `docker-compose`, you just have to change `DOCKER_GROUP: docker` to
`DOCKER_GROUP: root`.

This is a huge security risk, but hopefully you won't be running Jenkins on
MacOS as a build server. This issue does not affect Linux systems.

The above command will have to be run each time you run the container and mount
the docker socket into the container.
