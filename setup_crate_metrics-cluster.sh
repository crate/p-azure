#!/bin/bash

# * create Azure account
# * install the azure cli https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/

# follow instructions to log in on CLI
azure login

# switch to "azure resource manager" mode
azure config mode arm

# env
export CRATE_1K_METRIC_REGION="westeurope"
export CRATE_1K_METRIC_GROUP="azure1kmetrics"
export VM_TYPE_STD="Standard_D12_v2"
export VM_TYPE_SSD="Standard_DS12"

if [ "x$TMP_PASS" == "x" ]; then
  env
  echo "[ERROR] TMP_PASS environment variable must be set!"
  exit 1
fi

# needed for launching vms
azure provider register Microsoft.Storage
azure provider register Microsoft.Compute


# create resource group
azure group create -n $CRATE_1K_METRIC_GROUP -l $CRATE_1K_METRIC_REGION

# storage account (e.g. vm disks)
azure storage account create \
  --location $CRATE_1K_METRIC_REGION \
  --type LRS \
  --resource-group $CRATE_1K_METRIC_GROUP \
  cratemetricstorage

# premium account (for SSDs)
azure storage account create \
  --location $CRATE_1K_METRIC_REGION \
  --type PLRS \
  --resource-group $CRATE_1K_METRIC_GROUP \
  cratemetricprestorage

# create virtual network
azure network vnet create -g $CRATE_1K_METRIC_GROUP -n vnet_crate-metrics -a 10.0.0.0/16 -l $CRATE_1K_METRIC_REGION

# create subnets
azure network vnet subnet create -g $CRATE_1K_METRIC_GROUP -e vnet_crate-metrics -n subnet-pub_crate-metrics -a 10.0.1.0/24

# create network security group (NSG) for public subnet
azure network nsg create --resource-group $CRATE_1K_METRIC_GROUP --name nsg-pub_crate-metrics --location $CRATE_1K_METRIC_REGION

# rules for public NSG
azure network nsg rule create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --nsg-name nsg-pub_crate-metrics \
  --name allow-ssh \
  --priority 100 \
  --access Allow \
  --protocol '*' \
  --direction Inbound \
  --source-port-range '*' \
  --destination-port-range 22

azure network nsg rule create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --nsg-name nsg-pub_crate-metrics \
  --name allow-http \
  --priority 201 \
  --access Allow \
  --protocol '*' \
  --direction Inbound \
  --source-port-range '*' \
  --destination-port-range 80

azure network nsg rule create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --nsg-name nsg-pub_crate-metrics \
  --name allow-https \
  --priority 202 \
  --access Allow \
  --protocol '*' \
  --direction Inbound \
  --source-port-range '*' \
  --destination-port-range 443


# assign security groups to subnets
azure network vnet subnet set \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --vnet-name vnet_crate-metrics \
  --name subnet-pub_crate-metrics \
  --network-security-group-name nsg-pub_crate-metrics

# public IPs

# metrics1-azure-fir-io.westeurope.cloudapp.azure.com
azure network public-ip create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --name ip_metrics1 \
  --location $CRATE_1K_METRIC_REGION \
  --domain-name-label metrics1-azure-fir-io

# metrics2-azure-fir-io.westeurope.cloudapp.azure.com
azure network public-ip create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --name ip_metrics2 \
  --location $CRATE_1K_METRIC_REGION \
  --domain-name-label metrics2-azure-fir-io

# metrics3-azure-fir-io.westeurope.cloudapp.azure.com
azure network public-ip create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --name ip_metrics3 \
  --location $CRATE_1K_METRIC_REGION \
  --domain-name-label metrics3-azure-fir-io

# Network Interface Controllers (NIC)
# for each instance we need a NIC that has the public IP assigned

azure network nic create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --name nic_metrics1 \
  --location $CRATE_1K_METRIC_REGION \
  --subnet-name subnet-pub_crate-metrics \
  --subnet-vnet-name vnet_crate-metrics \
  --public-ip-name ip_metrics1 \
  --network-security-group-name nsg-pub_crate-metrics \
  --internal-dns-name-label metrics1-azure-fir-io

azure network nic create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --name nic_metrics2 \
  --location $CRATE_1K_METRIC_REGION \
  --subnet-name subnet-pub_crate-metrics \
  --subnet-vnet-name vnet_crate-metrics \
  --public-ip-name ip_metrics2 \
  --network-security-group-name nsg-pub_crate-metrics \
  --internal-dns-name-label metrics2-azure-fir-io

azure network nic create \
  --resource-group $CRATE_1K_METRIC_GROUP \
  --name nic_metrics3 \
  --location $CRATE_1K_METRIC_REGION \
  --subnet-name subnet-pub_crate-metrics \
  --subnet-vnet-name vnet_crate-metrics \
  --public-ip-name ip_metrics3 \
  --network-security-group-name nsg-pub_crate-metrics \
  --internal-dns-name-label metrics3-azure-fir-io


# azure vm image list --location westeurope --publisher OpenLogic

# create metrics slaves
for i in 1 2 3; do
  NAME="metrics$i"
  azure vm create \
    --resource-group $CRATE_1K_METRIC_GROUP \
    --name $NAME \
    --nic-name nic_$NAME \
    --vnet-name vnet_crate-metrics \
    --vnet-subnet-name subnet-pub_crate-metrics \
    --location $CRATE_1K_METRIC_REGION \
    --os-type Linux \
    --image-urn canonical:UbuntuServer:15.10:15.10.201602260 \
    --vm-size $VM_TYPE_SSD \
    --public-ip-name ip_$NAME \
    --admin-username azure \
    --admin-password $TMP_PASS \
    --storage-account-name cratemetricprestorage \
    --disable-boot-diagnostics
  # create disks for metrics{1..3}
  azure vm disk attach-new \
    --resource-group $CRATE_1K_METRIC_GROUP \
    --vm-name $NAME \
    --size-in-gb 160 \
    --host-caching None \
    --vhd-name vhdssd_$NAME
  # verify attached disks
  azure vm disk list --resource-group $CRATE_1K_METRIC_GROUP $NAME
done

