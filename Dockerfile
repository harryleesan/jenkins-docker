FROM jenkins/jenkins:lts
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
RUN curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && \
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
    workflow-aggregator:2.5 \
    workflow-scm-step:2.6 \
    git-client:2.7.1 \
    pipeline-multibranch-defaults:1.1 \
    docker-workflow:1.15.1 \
    bitbucket:1.1.8 \
    docker-slaves:1.0.7 \
    credentials-binding:1.15 \
    cloudbees-bitbucket-branch-source:2.2.10 \
    amazon-ecr:1.6 \
    antisamy-markup-formatter:1.5 \
    aws-credentials:1.23 \
    gatling:1.2.2 \
    matrix-auth:2.2 \
    mission-control-view:0.9.13 \
    pipeline-utility-steps:2.0.1 \
    resource-disposer:0.8 \
    slack:2.3 \
    ssh-credentials:1.13 \
    swarm:3.10 \
    windows-slaves:1.3.1 \
    ws-cleanup:0.34 \
    blueocean:1.4.2

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/bin/bash", "-c", "/entrypoint.sh"]
