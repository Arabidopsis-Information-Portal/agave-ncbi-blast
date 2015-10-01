FROM ubuntu:14.04
WORKDIR /home
MAINTAINER Matthew Vaughn <vaughn@tacc.utexas.edu>

RUN apt-get update -qq --fix-missing; apt-get -y install wget; apt-get clean

RUN wget -q -O ncbi-blast-2.2.30+-x64-linux.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.2.30/ncbi-blast-2.2.30+-x64-linux.tar.gz; \
  tar -zxf ncbi-blast-2.2.30+-x64-linux.tar.gz -C /opt/; \
  ln -s /opt/ncbi-blast-2.2.30+/ /opt/blast; \
  rm ncbi-blast-2.2.30+-x64-linux.tar.gz

ENV PATH $PATH:/opt/blast/bin

RUN mkdir -p /opt/databases
ENV BLASTDB /opt/databases
WORKDIR /home
