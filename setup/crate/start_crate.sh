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

CRATE_CONTAINERS=($(docker ps -a | grep -o "swarm-node-.*" | cut -d/ -f1 | cut -d- -f3 | sort -g))
NEW_CONTAINERS=()
LAST=0

if [ ${#CRATE_CONTAINERS[@]} -ne 0 ]; then
   LAST=${CRATE_CONTAINERS[${#CRATE_CONTAINERS[@]}-1]}
   FIRST=${CRATE_CONTAINERS[0]}
   for i in $(eval echo "{$FIRST..$LAST}"); do
       if [[ ! ${CRATE_CONTAINERS[*]} =~ $i ]]; then
           echo "swarm-node-$i";
       NEW_CONTAINERS+=(swarm-node-$i)
       fi
   done
   LAST=$(($LAST + 1))
fi

ADD=$(($INSTANCES + ${#NEW_CONTAINERS[@]} - 1))
for i in $(eval echo "{$(($LAST))..$(($LAST + $ADD))}"); do
    NEW_CONTAINERS+=(swarm-node-$i)
done

for i in "${NEW_CONTAINERS[@]}"; do
    NODE_NAME=$i
    docker run -d -p 4200:4200 -p 4300:4300 \
        --env="constraint:node==$NODE_NAME" \
        --env="CRATE_HEAP_SIZE=30g" \
        --name $NODE_NAME \
        -v /mnt:/data \
        -v /media/data1:/backup \
        crate:latest \
        crate  \
        -Des.cluster.name=crate-swarm \
        -Des.indices.store.throttle.max_bytes_per_sec=700mb \
        -Des.indices.store.throttle.type=none \
        -Des.indices.memory.index_buffer_size=25% \
        -Des.bootstrap.mlockall=true \
        -Des.index.store.type=mmapfs \
        -Des.node.master=$ISMASTER \
        -Des.node.data=$ISDATA \
        -Des.node.name=$NODE_NAME \
        -Des.http.port=4200 \
        -Des.transport.tcp.port=4300 \
        -Des.transport.publish_host=$NODE_NAME \
        -Des.multicast.enabled=false \
        -Des.discovery.zen.minimum_master_nodes=2  \
        -Des.discovery.type=srv \
        -Des.discovery.srv.query=_azure1k._srv.fir.io \
        -Des.path.data=/data
done
