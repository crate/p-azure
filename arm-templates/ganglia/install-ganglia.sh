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

COPY_INDEX="$1"
GANGLIA_CLUSTER="crate-scaleunit-$1"

# data disks
bash autopart.sh

# tools
apt-get install -y htop iotop iptraf ganglia-monitor ganglia-monitor-python
# ganglia
wget -O /etc/ganglia/gmond.conf https://raw.githubusercontent.com/crate/p-azure/master/arm-templates/ganglia/gmond-ganglia.conf
# replace _HOSTNAME_ with real hostname
sed -i "s/_HOSTNAME_/$(hostname)/g" /etc/ganglia/gmond.conf
sed -i "s/_CLUSTER_/${GANGLIA_CLUSTER}/g" /etc/ganglia/gmond.conf
# restart ganglia
killall gmond
service ganglia-monitor restart

echo "Install complete!"
