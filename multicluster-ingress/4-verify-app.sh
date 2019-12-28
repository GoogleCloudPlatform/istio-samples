#!/usr/bin/env bash

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


source ./common.sh

for svc in "${CLUSTERS[@]}" ; do
    CTX="${svc%%:*}"
    printf "\n\n Calling ZonePrinter on $CTX...\n"
    kubectx $CTX
    IP=`kubectl get service/istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
    curl $IP
done
