#!/bin/bash

while [[ $# > 1 ]]; do
  key="$1"

  case $key in
    -i|--instances-type)
      INSTANCE_TYPE="$2"
      shift
    ;;
    -a|--add-instances)
      NUM_INSTANCES="$2"
      shift
    ;;
    -p|--password)
      PASSWORD="$2"
      shift
    ;;
    *)
      # unknown option
    ;;
  esac
  shift
done

echo "Creating $NUM_INSTANCES instances of the swarm $INSTANCE_TYPE type..."

RESOURCE_GROUP=azure1k
VNET_NAME=vnet-azure1k
VNET_SUBNET=subnet-1-azure1k
REGION=westeurope
STORAGE_ACCOUNT=azure1kswarmagentsplrs
USER=swarm

URN=canonical:UbuntuServer:15.10:15.10.201602260

EXISTING_INSTANCES=$(azure vm list --resource-group azure1k | awk '{print $3}' \
  | grep swarm-$INSTANCE_TYPE | cut -d- -f3 | sort -g)
LAST_INSTANCE=$(echo $EXISTING_INSTANCES | tr " " "\n" | tail -1)


for i in $(eval echo "{$(($LAST_INSTANCE + 1))..$(($LAST_INSTANCE + $NUM_INSTANCES))}"); do
  ( NAME="swarm-$INSTANCE_TYPE-$i"
    echo $NAME
    azure vm create \
      --custom-data cloud-$INSTANCE_TYPE.yaml \
      --resource-group $RESOURCE_GROUP \
      --name $NAME \
      --nic-name nic_$NAME \
      --vnet-name $VNET_NAME \
      --vnet-subnet-name $VNET_SUBNET \
      --location $REGION \
      --os-type Linux \
      --image-urn $URN \
      --vm-size Standard_DS12 \
      --data-disk-vhd disk-vhd-$NAME \
      --data-disk-size 300 \
      --admin-username $USER \
      --admin-password $PASSWORD \
      --storage-account-name $STORAGE_ACCOUNT \
      --disable-boot-diagnostics

    # if [ $INSTANCE_TYPE = "agent" ]; then
    #   azure vm disk attach-new \
    #     --resource-group $RESOURCE_GROUP \
    #     --vm-name $NAME \
    #     --size-in-gb 256 \
    #     --host-caching None \
    #     --vhd-name vhdssd_$NAME-1

    #   azure vm disk attach-new \
    #     --resource-group $RESOURCE_GROUP \
    #     --vm-name $NAME \
    #     --size-in-gb 256 \
    #     --host-caching None \
    #     --vhd-name vhdssd_$NAME-2

    #   azure vm disk list --resource-group $RESOURCE_GROUP $NAME
    # fi 
  ) &
done
