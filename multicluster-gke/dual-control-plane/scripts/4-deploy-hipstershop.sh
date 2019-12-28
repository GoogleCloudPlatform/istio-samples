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

# Get the Istio IngressGateway IP for both clusters
kubectl config use-context $CTX_1
GWIP1=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

kubectl config use-context $CTX_2
GWIP2=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')


# Populate YAML / Deploy to Cluster 1
log "Deploying Hipstershop on Cluster 1..."
gcloud config set project $PROJECT_1
gcloud container clusters get-credentials $CLUSTER_1 --zone $ZONE
kubectl config use-context $CTX_1
pattern='.*- address:.*'
replace="  - address: "$GWIP2""
gsed -r -i "s|$pattern|$replace|g" cluster1/service-entries.yaml
kubectl create namespace hipster1
kubectl label namespace hipster1 istio-injection=enabled
kubectl apply -n hipster1  -f ./cluster1
log "...done with cluster 1."


# Populate YAML /  Deploy to Cluster 2
log "Deploying Hipstershop on Cluster 2..."
gcloud config set project $PROJECT_2
gcloud container clusters get-credentials $CLUSTER_2 --zone $ZONE
kubectl config use-context $CTX_2
pattern='.*- address:.*'
replace="  - address: "$GWIP1""
gsed -r -i "s|$pattern|$replace|g" cluster2/service-entries.yaml
kubectl create namespace hipster2
kubectl label namespace hipster2 istio-injection=enabled
kubectl apply -n hipster2  -f ./cluster2
log "...done with cluster 2."


