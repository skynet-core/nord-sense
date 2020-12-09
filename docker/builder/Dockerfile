FROM alpine:3.12.1

ARG VERSION=1.4.2

RUN apk update && apk upgrade && apk add --no-cache musl musl-dev gcc g++ gdb libressl-dev \
    gcc-objc curl git pcre-dev openssl-dev bash tar xz wget sudo

RUN cd /tmp && wget https://nim-lang.org/download/nim-${VERSION}.tar.xz && \
    tar -xf nim-${VERSION}.tar.xz && cd nim-${VERSION} && sh build.sh && bin/nim c koch && \
    ./koch boot -d:release && ./koch tools && ./install.sh /opt && cp bin/* /opt/nim/bin/ && \
    rm -rf /tmp/*

RUN addgroup -g 1000 nim && adduser -h /home/nim -g "Nim User" -s /bin/bash -D -u 1000 -G nim nim && \
    echo "%nim         ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

ENV PATH="${PATH}:/opt/nim/bin"
USER nim
WORKDIR /home/nim
CMD [ "bash" ]