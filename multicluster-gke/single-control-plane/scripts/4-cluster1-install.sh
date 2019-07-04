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

PROJECT_ID="${PROJECT_ID:?PROJECT_ID env variable must be specified}"
ISTIO_VERSION=${ISTIO_VERSION:=1.2.2}
cluster1zone="us-east1-b"
cluster2zone="us-central1-b"

ctx1="gke_${PROJECT_ID}_${cluster1zone}_cluster-1"
ctx2="gke_${PROJECT_ID}_${cluster2zone}_cluster-2"

kubectl config use-context $ctx1

log "Downloading Istio ${ISTIO_VERSION}..."
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

# Install istio
cat istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init/files/crd-* > istio_master.yaml
helm template istio-${ISTIO_VERSION}/install/kubernetes/helm/istio --name istio --namespace istio-system >> istio_master.yaml

kubectl create ns istio-system
kubectl label namespace default istio-injection=enabled
kubectl apply -f istio_master.yaml

