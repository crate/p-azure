# Deployment Scripts

## Azure

### Resource groups

**TODO: rename to have consistant naming!!!**

* crate1k1network (VNET, VPN, ...)
    * network.json
* crate1k1monitoring (Ganglia)
    * ganglia.json
    * gangliad.parameters.json
* crate1k1shared (Swarm managers, Consul agents)
    * swarmmanagers.json
    * swarmmanagers.paramters.json
* crate1k1masterunit (Crate masters, Swarm agents)
    * scaleunit.json
    * masterunit.parameters.json
* crate1k1scaleunit{1..11} (Crate data, Swarm agents)
    * scaleunit.json
    * scaleunit.parameters.json (scaleUnitNumber {1..11})


### Prepare Swarm, monitorying and crate clusters

```console
# 1. create network
azure group crate crate1k1network
azure group deployment -f network.json -g crate1k1network -v
# 2. create monitoring
azure group crate crate1k1monitoring
azure group deployment -f ganglia.json -e ganglia.parameters.json -g crate1k1network -v
# 3. create shared resources
azure group crate crate1k1shared
azure group deployment -f swarmmanager.json -e swarmmanager.parameters.json -g crate1k1shared -v
# 4. create master unit
azure group crate crate1k1masterunit
azure group deployment -f masterunit.json -e masterunit.parameters.json -g crate1k1masterunit -v
```

### Starting Scale units

`$ ./start_scaleunits.sh 1 11`

```sh
#!/bin/bash -e

for unit in `seq $1 $2`; do
  RG="crate1k1scaleunit${unit}"
  echo $RG
  if [ "$3" == "--delete" ]; then
    yes | azure group delete $RG
  fi
  azure group create $RG westus
  azure group deployment create -f swarm_nodes_scale_unit.deploy.json -e swarm_nodes_scale_unit.parameters${unit}.json -g $RG -v
done
```

## Docker Crate


Docker run command (script)

#!/bin/bash -e
#
# Usage: ./start_crate.sh TYPE START END PREFIX
# e.g. ./start_crate.sh master 1 3 swarm-crate-master-
# e.g. ./start_crate.sh data 1 1100 swarm-crate-node-
#

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

START=$2
END=$3
PREFIX="$4"

for i in `seq $START $END`; do
    NODE_NAME=${PREFIX}${i}
    docker run -d \
        -p 4200:4200 \
        -p 4300:4300 \
        --name $NODE_NAME \
        --env="constraint:node==$NODE_NAME" \
        --env="CRATE_HEAP_SIZE=14g" \
        -v /mnt:/data \
        -v /media/data1:/backup \
        crate/crate:1k1 \
        crate \
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
        -Des.path.data=/data \
        -Des.path.logs=/data1
done



## Naked Crate


count.sh
#!/bin/bash -e
curl -sXPOST '127.0.0.1:4200/_sql?pretty' -d '{"stmt":"select count(*) as num_nodes from sys.nodes"}'

watch -n 10 "/bin/bash count.sh"

