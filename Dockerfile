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

# Install extra plugins for Jenkins (you can remove/add these)
RUN /usr/local/bin/install-plugins.sh \
    workflow-aggregator:2.5 \
    workflow-scm-step:2.6 \
    git-client:2.7.0 \
    pipeline-multibranch-defaults:1.1 \
    docker-workflow:1.14 \
    bitbucket:1.1.8 \
    docker-slaves:1.0.7 \
    envinject:2.1.5 \
    credentials-binding:1.14 \
    cloudbees-bitbucket-branch-source:2.2.9

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/bin/bash", "-c", "/entrypoint.sh"]
