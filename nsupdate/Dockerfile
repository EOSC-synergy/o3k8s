# set the base image. default is alpine
ARG base=alpine
# set the tag (e.g. 3.14, latest, ... )
ARG tag=3.14

# Base image, e.g. debian:stable or ubuntu:bionic
FROM ${base}:${tag}
RUN apk update && apk upgrade
RUN apk --no-cache add curl
COPY ./nsupdate-fedcloud.sh /usr/bin/
RUN cd /usr/bin && ln -s nsupdate-fedcloud.sh nsupdate-fedcloud
CMD nsupdate-fedcloud