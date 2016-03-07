#!/bin/bash

# * create Azure account
# * install the azure cli https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/

# follow instructions to log in on CLI
azure login

# switch to "azure resource manager" mode
azure config mode arm

# env
export CRATE_1K_METRIC_REGION="westeurope"
export CRATE_1K_METRIC_GROUP="azure1k"
export VM_TYPE_SSD="Standard_DS12"
export TMP_PASS="Metricspasswd1@"

if [ "x$TMP_PASS" == "x" ]; then
  env
  echo "[ERROR] TMP_PASS environment variable must be set!"
  exit 1
fi

# needed for launching vms
azure provider register Microsoft.Storage
azure provider register Microsoft.Compute

# create resource group
#azure group create -n $CRATE_1K_METRIC_GROUP -l $CRATE_1K_METRIC_REGION

# premium account (for SSDs)
azure storage account create \
  --location $CRATE_1K_METRIC_REGION \
  --type PLRS \
  --resource-group $CRATE_1K_METRIC_GROUP \
  cratemetricprestorage

# Network Interface Controllers (NIC)
# for each instance we need a NIC that has the public IP assigned

azure network nic create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --name nic_metrics1 \
  --location $CRATE_1K_METRIC_REGION \
  --subnet-name subnet-1-azure1k \
  --subnet-vnet-name vnet-azure1k \
  --network-security-group-name nsg-azure1k-default \

azure network nic create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --name nic_metrics2 \
  --location $CRATE_1K_METRIC_REGION \
  --subnet-name subnet-1-azure1k \
  --subnet-vnet-name vnet-azure1k \
  --network-security-group-name nsg-azure1k-default \

azure network nic create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --name nic_metrics3 \
  --location $CRATE_1K_METRIC_REGION \
  --subnet-name subnet-1-azure1k \
  --subnet-vnet-name vnet-azure1k \
  --network-security-group-name nsg-azure1k-default \

# azure vm image list --location westeurope --publisher OpenLogic

# create metrics slaves
for i in 1 2 3; do
  NAME="metrics$i"
  azure vm create \
    --resource-group $CRATE_1K_METRIC_GROUP \
    --name $NAME \
    --nic-name nic_$NAME \
    --vnet-name vnet-azure1k \
    --vnet-subnet-name subnet-1-azure1k \
    --location $CRATE_1K_METRIC_REGION \
    --os-type Linux \
    --image-urn canonical:UbuntuServer:15.10:15.10.201602260 \
    --vm-size $VM_TYPE_SSD \
    --admin-username azure \
    --admin-password $TMP_PASS \
    --storage-account-name cratemetricprestorage \
    --disable-boot-diagnostics \
    --custom-data cloud-metrics-init.yml \
    --data-disk-vhd vhd-$NAME \
    --data-disk-size 160 	    

  # verify attached disks
  azure vm disk list --resource-group $CRATE_1K_METRIC_GROUP $NAME
done

