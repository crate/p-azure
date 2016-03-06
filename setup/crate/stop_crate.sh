#!/bin/bash -x

docker kill $(docker ps -a | grep swarm-agent | awk '{print $1}')
docker rm $(docker ps -a | grep swarm-agent | awk '{print $1}')