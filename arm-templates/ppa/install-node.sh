#!/bin/bash
#
# Licensed to CRATE Technology GmbH ("Crate") under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  Crate licenses
# this file to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.  You may
# obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#
# However, if you have executed another commercial license agreement
# with Crate these terms will supersede the license and you may use the
# software solely pursuant to the terms of the relevant commercial agreement.


echo "Begin execution of script extension on ${HOSTNAME}"

if [ "${UID}" -ne 0 ];
then
    echo "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

# parameters
SCALEUNIT="$1"
NODE_TYPE="$2"

# data disks
bash autopart.sh


# do not require tty
echo "Defaults:azureuser !requiretty" >> /etc/sudoers

# Ruxit agent
# wget -O ruxit-Agent-Linux-1.87.198.sh https://akp88036.live.ruxit.com/installer/agent/unix/latest/3xEDwbMRpYzbTI5H
# bash ruxit-Agent-Linux-1.87.198.sh

# tools
apt-get install -y python-software-properties software-properties-common
add-apt-repository -y ppa:crate/testing
apt-get update
apt-get upgrade -y

apt-get purge lxc
rm -rf /etc/lxc

apt-get install -y htop iotop iptraf ganglia-monitor ganglia-monitor-python openjdk-8-jre-headless
apt-get install -y crate
systemctl enable crate

mkdir -pv /mnt/crate
sudo chown -R crate:crate /mnt/crate
mkdir -pv /media/data1/cratelogs
sudo chown -R crate:crate /media/data1/cratelogs

# crate.yml
wget -O /etc/crate/crate.yml https://raw.githubusercontent.com/crate/p-azure/master/arm-templates/ppa/crate.yml
sed -i "s/_HOSTNAME_/$(hostname)/g" /etc/crate/crate.yml
if [ "$NODE_TYPE" == "master" ]; then
  sed -i "s/_MASTER_/true/g" /etc/crate/crate.yml
  sed -i "s/_DATA_/false/g" /etc/crate/crate.yml
fi
if [ "$NODE_TYPE" == "data" ]; then
  sed -i "s/_MASTER_/false/g" /etc/crate/crate.yml
  sed -i "s/_DATA_/true/g" /etc/crate/crate.yml
fi

# env defaults
echo "CRATE_HEAP_SIZE=28g" >> /etc/default/crate
echo "MAX_OPEN_FILES=65535" >> /etc/default/crate
echo "MAX_LOCKED_MEMORY=unlimited" >> /etc/default/crate

# limits
echo "* - nofile  65535" >> /etc/security/limits.conf
echo "* - memlock unlimited" >> /etc/security/limits.conf

# ganglia
wget -O /etc/ganglia/gmond.conf https://raw.githubusercontent.com/crate/p-azure/master/arm-templates/ganglia/gmond-crate-node.conf
# replace _HOSTNAME_ with real hostname
sed -i "s/_HOSTNAME_/$(hostname)/g" /etc/ganglia/gmond.conf
sed -i "s/_SERVER_/10.0.0.99/g" /etc/ganglia/gmond.conf
sed -i "s/_GROUP_/crate-scaleunit-$SCALEUNIT/g" /etc/ganglia/gmond.conf
# restart ganglia
killall gmond
/etc/init.d/ganglia-monitor start

systemctl restart crate

echo "Install complete!"
