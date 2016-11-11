FROM ubuntu:latest

MAINTAINER Tornike Zedginidze <tokozedg@gmail.com>

RUN \
      apt-get clean && \
      apt-get update && \
      apt-get install -y sphinx-common python-sphinxcontrib-programoutput \
      python-sphinxcontrib.seqdiag python-tabulate entr make && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt/devops-wiki/

EXPOSE 80
CMD make watch
