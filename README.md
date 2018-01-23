# Jenkins in Docker
### Author: Harry Lee

## What's inside?
- `docker`
- `docker-compose`
- `aws-cli`

## Usage

To use `docker-in-docker`, we are utilizing the `docker-sidecar` method by
mounting the host docker socket into the Jenkins container.

```bash
docker run \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name jenkins \
  halosan/jenkins:latest
```

To persist Jenkins data and configurations read the [Official Doc](https://github.com/jenkinsci/docker/blob/master/README.md).
The official doc recommends using a _volume container_ to persist data. A host
directory can also be used, but that requires some permission tweaking to the
host directory.

```bash
docker run -p 8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins \
  halosan/jenkins:latest
```

## Gotchas

If you are running docker on **MacOS**, the _jenkins_ user in the container will
not have permission to access docker on the host. A work around for this
(security risk) is to add _jenkins_ user to the _root_ group.

```bash
docker exec -it --user root jenkins bash
usermod -aG root jenkins
```

This is a huge security risk, but hopefully you won't be running Jenkins on
MacOS as a build server. This issue does not affect Linux systems.
