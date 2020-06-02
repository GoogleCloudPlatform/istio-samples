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

set -euo pipefail
source ./scripts/env.sh

# Get Ingress gateway IP on Cluster 2
kubectl config use-context $CTX_2
GWIP2=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Cluster 1
log "🛍 Prepare for ProductCatalog GKE migration / still sending all traffic to VM..."
log "☸️   Creating a service entry and virtualservice on cluster1..."
kubectl config use-context ${CTX_1}
pattern='.*- address:.*'
replace="  - address: "$GWIP2""
gsed -r -i "s|$pattern|$replace|g" productcatalog-gke/serviceentry-cluster1.yaml
kubectl apply -f productcatalog-gke/serviceentry-cluster1.yaml
kubectl apply -f productcatalog-gke/vs-0-cluster1.yaml

# Cluster 2
log "☸️   Creating a deployment, service, and virtualservice on cluster2..."
kubectl config use-context ${CTX_2}
kubectl apply -f productcatalog-gke/deployment.yaml
kubectl apply -f productcatalog-gke/service-cluster2.yaml
kubectl apply -f productcatalog-gke/vs-0-cluster2.yaml
log "✅  done."


