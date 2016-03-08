#!/bin/bash -x

NODE_TYPE=$1

if [ -z "$NODE_TYPE" ]; then
    echo "Crate node type is not defined";
    exit 0;
fi

case $NODE_TYPE in
    client)
        echo 'Starting client node'
        ISMASTER=false
        ISDATA=false
        ;;
    data)
        echo 'Starting data node'
        ISMASTER=false
        ISDATA=true
        ;;
    master)
        echo 'Starting master node'
        ISMASTER=true
        ISDATA=false
        ;;
    *)
esac

while [[ $# > 1 ]]; do
  key="$1"

  case $key in
    -a|--add-instances)
      INSTANCES="$2"
      shift
    ;;
    *)
      # unknown option
    ;;
  esac
  shift
done

IFS='' read -r -a CRATE_CONTAINERS <<< \
    $(docker ps -f "name=swarm-node" --format "{{.Names}}" | cut -d/ -f1 | cut -d- -f3 | sort -g)

LAST=${CRATE_CONTAINERS[${#CRATE_CONTAINERS[@]}-1]} 
FIRST=${CRATE_CONTAINERS[0]}

declare -a NEW_CONTAINERS=($(for i in $(eval echo "{$FIRST..$LAST}"); do 
    if [[ ! ${CRATE_CONTAINERS[*]} =~ $i ]]; then 
        echo "swarm-node-$i";
    fi
 done))

ADD=$(($INSTANCES - ${#NEW_CONTAINERS[@]}))
for i in $(eval echo "{$(($LAST + 1))..$(($LAST + $ADD))}"); do
    NEW_CONTAINERS+=(swarm-node-$i)
done

for i in $(NEW_CONTAINERS[@]); do
    NODE_NAME=swarm-node-$i
    docker run -d -p 4200:4200 -p 4300:4300 --env="constraint:node==$NODE_NAME" --env="CRATE_HEAP_SIZE=14g"  \
        -v /mnt/data/1:/data
        --name $NODE_NAME
        crate:latest \
        crate  \
        -Des.cluster.name=crate-swarm \
        -Des.indices.store.throttle.max_bytes_per_sec=200mb \
        -Des.indices.memory.index_buffer_size=15% \
        -Des.bootstrap.mlockall=true \
        -Des.index.store.type=mmapfs \
        -Des.node.master=$ISMASTER \
        -Des.node.data=$ISDATA \
        -Des.http.port=4200 \
        -Des.transport.tcp.port=4300 \
        -Des.transport.publish_host=$NODE_NAME \
        -Des.multicast.enabled=false  \
        -Des.discovery.zen.minimum_master_nodes=2  \
        -Des.discovery.type=srv  \
        -Des.discovery.srv.query=_azure1k._srv.fir.io \
        -Des.path.data=/data
done
