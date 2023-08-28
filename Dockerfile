FROM debian:11

ARG REPO_HOME=/home/runner
ARG REPO_BRANCH=master
ARG REPO_URL=https://github.com/romeroalx/pdns.git
ARG DOCKER_GID=122

ENV CLANG_VERSION='13'

# Reusable layer for base update
RUN apt-get update && apt-get -y dist-upgrade && apt-get clean

# Install basic SW and debugging tools
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    sudo git curl gnupg software-properties-common wget \
    ca-certificates apt-utils build-essential vim \
    iproute2 net-tools iputils-* ifupdown cmake acl \
    npm time mariadb-client postgresql-client jq python

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Run as user "runner", uid 1001, gid 122. Make this user a passwordless sudoer
RUN echo ${DOCKER_GID}
RUN groupadd runner
RUN useradd -u 1001 -ms /bin/bash -g runner runner
RUN echo "runner ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers
USER runner

# Clone repo an execute basic configuration. Do not delete folder
RUN mkdir -p ${REPO_HOME}
WORKDIR ${REPO_HOME}
RUN git clone ${REPO_URL}

# Install required packages
WORKDIR ${REPO_HOME}/pdns
RUN git checkout origin/${REPO_BRANCH}
RUN build-scripts/gh-actions-setup-inv
RUN inv apt-fresh
RUN inv install-clang
RUN inv install-clang-tidy-tools
RUN inv install-auth-build-deps
RUN inv install-rec-build-deps
RUN inv install-dnsdist-build-deps

# Copy permissions for /opt and node_modules like Github runner VMs
RUN sudo mkdir -p /usr/local/lib/node_modules
RUN sudo chmod 777 /opt /usr/local/bin /usr/share /usr/local/lib/node_modules
RUN sudo chmod 777 -R /opt/pdns-auth

WORKDIR ${REPO_HOME}
RUN rm -rf 
