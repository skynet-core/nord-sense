FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get full-upgrade -y && \
    apt-get install -y ruby ruby-dev rubygems build-essential sudo && \
    gem install --no-document fpm && fpm --version && apt-get clean -y && \
    apt-get autoremove -y && rm -rf /tmp && rm -rf /var/cache/apt

RUN addgroup --gid 1000 fpm && \
    adduser --gecos "FPM User" --home /home/fpm --disabled-password --shell /usr/bin/bash --uid 1000 --gid 1000 fpm && \
    echo "%fpm         ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

USER fpm

WORKDIR /home/fpm
VOLUME /home/fpm
CMD [ "bash" ]