#!/bin/bash

while [[ $# > 1 ]]; do
  key="$1"

  case $key in
    -i|--instances-type)
      INSTANCE_TYPE="$2"
      shift # past argument
    ;;
    -s|--start)
      START="$2"
      shift # past argument
    ;;
    -e|--end)
      END="$2"
      shift # past argument
    ;;
    *)
      # unknown option
    ;;
  esac
  shift
done

RESOURCE_GROUP=azure1k

for i in $(eval echo "{$START..$END}"); do
  ( NAME="swarm-$INSTANCE_TYPE-$i";
    echo -e "y" | azure vm delete --resource-group $RESOURCE_GROUP $NAME ) &
done
