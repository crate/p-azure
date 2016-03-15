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

# Usage:
# To use this script you have to duplicate the scaleunit parameter file first.
# Create a scaleunit parameter file for each scaleunit and name them like:
# scaleunit.parameters{1..x}.json
# Then change the parameter 'scaleUnitNumber' in each file accordingly.

for unit in `seq $1 $2`; do
  RG="crate1k1scaleunit${unit}"
  echo $RG
  if [ "$3" == "--delete" ]; then
    yes | azure group delete $RG
  fi
  azure group create $RG westus
  azure group deployment create -f scaleunit.json -e scaleunit.parameters${unit}.json -g $RG -v &
done

