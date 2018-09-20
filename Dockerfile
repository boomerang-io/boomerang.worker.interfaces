#Import the base docker image built on top of Alpine
FROM alpine:3.8 

#Add Packages
RUN apk add --no-cache git openssh-client bash sed grep coreutils openjdk8 maven

WORKDIR /plugins

ADD ./plugins .