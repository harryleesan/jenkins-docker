FROM jenkins/jenkins:lts-jdk11
MAINTAINER Harry Lee

USER root

# Install the latest Docker CE binaries
RUN apt-get update && apt-get -y install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg2 \
      software-properties-common \
      rsync \
      sudo

RUN curl -sSL https://get.docker.com/ | sh

# RUN usermod -a -G docker jenkins

# Install latest docker-compose binary
ENV DOCKER_COMPOSE_VERSION 1.27.4
RUN curl -L https://github.com/docker/compose/releases/download/"${DOCKER_COMPOSE_VERSION}"/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Install aws-cli
RUN apt-get install -y \
      jq \
      groff \
      python-pip \
      python &&\
    pip install --upgrade \
      pip \
      awscli

RUN mkdir /var/jenkins_home/.aws
VOLUME ["/var/jenins_home/.aws"]

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

RUN mkdir /var/jenkins_home/.kube
VOLUME ["/var/jenkins_home/.kube"]

# Install extra plugins for Jenkins (you can remove/add these)
RUN /usr/local/bin/install-plugins.sh \
    workflow-multibranch:2.22 \
    git-client:3.5.1 \
    docker-workflow:1.25 \
    bitbucket:1.1.25 \
    docker-slaves:1.0.7 \
    docker-plugin:1.2.1 \
    credentials-binding:1.24 \
    cloudbees-bitbucket-branch-source:2.9.4 \
    amazon-ecr:1.6 \
    antisamy-markup-formatter:2.1 \
    aws-credentials:1.28 \
    matrix-auth:2.6.4 \
    mission-control-view:0.9.16 \
    pipeline-utility-steps:2.6.1 \
    resource-disposer:0.14 \
    ssh-credentials:1.18.1 \
    swarm:3.24 \
    ws-cleanup:0.38 \
    blueocean:1.24.3

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/bin/bash", "-c", "/entrypoint.sh"]
