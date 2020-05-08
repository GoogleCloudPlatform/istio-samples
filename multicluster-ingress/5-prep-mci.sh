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

log "Adding health check and updating the IngressGateway..."
for svc in "${CLUSTERS[@]}" ; do
    CTX="${svc%%:*}"
    kubectx $CTX

    # prep ingressgateway to be used as a GCLB backend
    kubectl apply -f manifests/healthcheck.yaml

    # make the ingressgateway a NodePort svc
    kubectl -n istio-system patch svc istio-ingressgateway \
    --type=json -p="$(cat manifests/istio-ingressgateway-patch.json)" \
    --dry-run=true -o yaml | kubectl apply -f -
done