# Jenkins in Docker (with `aws-cli` and `kubectl`)
### Author: Harry Lee

## What's installed?
- `docker`
- `docker-compose`
- `aws-cli`
- `kubectl`


## Usage

### TL;DR

**Using** `docker-compose`:
```bash
docker volume create jenkins_home
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
  -v $(pwd)/kube:/var/jenkins_home/.kube:ro \
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
To allow **aws** in the container access to your **AWS resources**, in the `aws`
folder enter your aws credentials in the `config` and `credentails` files.

Alternatively, you can mount your own `~/.aws` folder into
`/var/jenkins_home/.aws`.

### Kubernetes Credentials
To allow **kubectl** in the container access to your **Kubernetes resources**, in
the `kube` folder enter your credentials in the `config` file.

Alternatively, you can mount your own `~/.kube` folder into
`/var/jenkins_home/.kube`.

### (DEPRECATED) Workspace issue workaround
This issue only applies if you are building a pipeline using the `docker`
plugin.
Executing `sh` in the Jenkins container through _docker.inside_ using the mounted
docker socket means that you are using the workspace on the host. This means
that the directory needs to exist on the host, or you will get
'`/jenkins-log.txt: Directory nonexistent`' error.

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

The above command will have to be run each time you run the container
and mount the docker socket into the container (does not apply when using docker-compose).

## Backup Jenkins Configurations to AWS S3

Here is a script that can be incorporated into a scheduled job. Ensure that your
AWS user has the policy to `PutObject` into the specified S3 bucket.

```bash
# Courtesy of https://thepracticalsysadmin.com/backing-up-jenkins-configurations-to-s3/

# Delete all files in the workspace
rm -rf *

# Create a directory for the job definitions
mkdir -p build/jobs

# Copy global configuration files into the workspace
cp $JENKINS_HOME/*.xml build/

# Copy keys and secrets into the workspace
cp $JENKINS_HOME/identity.key.enc build/
cp $JENKINS_HOME/secret.key build/
cp $JENKINS_HOME/secret.key.not-so-secret build/
cp -r $JENKINS_HOME/secrets build/

# Copy user configuration files into the workspace
cp -r $JENKINS_HOME/users build/

# Copy custom Pipeline workflow libraries
# cp -r $JENKINS_HOME/workflow-libs $BUILD_ID

# Copy job definitions into the workspace
rsync -am --include='config.xml' --include='*/' --prune-empty-dirs --exclude='*' $JENKINS_HOME/jobs/ build/jobs/

# Create an archive from all copied files (since the S3 plugin cannot copy folders recursively)
tar czf jenkins-configuration.tar.gz -C build .

# Remove the directory so only the tar.gz gets copied to S3
rm -rf build

aws s3 cp jenkins-configuration.tar.gz s3://halosan/jenkins/backups/

rm -rf jenkins-configuration.tar.gz
```
