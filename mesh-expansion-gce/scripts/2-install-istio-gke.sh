#!/usr/bin/env bash

# Copyright 2019 Google LLC
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
log() { echo "$1" >&2; }

# set vars
PROJECT_ID="${PROJECT_ID:?PROJECT_ID env variable must be specified}"
ZONE="us-central1-b"
CLUSTER_NAME="mesh-exp-gke"
CTX="gke_${PROJECT_ID}_${ZONE}_${CLUSTER_NAME}"


# configure cluster context
gcloud config set project $PROJECT_ID
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
kubectl config use-context $CTX

# set up istio permissions
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"

# get istio 1.1.1 
log "Downloading Istio 1.1.1..."
wget https://github.com/istio/istio/releases/download/1.1.1/istio-1.1.1-linux.tar.gz
tar -xzf istio-1.1.1-linux.tar.gz
rm -r istio-1.1.1-linux.tar.gz

# install the istio control plane via helm
log "Installing CRDs to the GKE cluster..."
for i in istio-1.1.1/install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
cat istio-1.1.1/install/kubernetes/namespace.yaml > scripts/istio.yaml
helm template istio-1.1.1/install/kubernetes/helm/istio --name istio --namespace istio-system --set global.meshExpansion.enabled=true >> scripts/istio.yaml
kubectl apply -f scripts/istio.yaml

log "...Success."