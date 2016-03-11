#!/bin/bash -x

while [[ $# > 1 ]]; do
  key="$1"

  case $key in
    -p|--pattern)
      PATTERN="$2"
      shift
    ;;
    *)
      # unknown option
    ;;
  esac
  shift
done

docker kill $(docker ps -a | grep crate | awk '{print $1}')
docker rm $(docker ps -a | grep crate | awk '{print $1}')
