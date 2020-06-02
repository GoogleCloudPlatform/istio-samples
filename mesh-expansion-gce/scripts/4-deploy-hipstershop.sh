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
log() { echo "$1" >&2; }

PROJECT_ID="${PROJECT_ID:?PROJECT_ID env variable must be specified}"
ZONE="us-central1-b"
CLUSTER_NAME="mesh-exp-gke"
CTX="gke_${PROJECT_ID}_${ZONE}_${CLUSTER_NAME}"

# configure cluster context
gcloud config set project $PROJECT_ID
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
kubectl config use-context $CTX

# deploy sample app to GKE
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml

# remove the cluster-based productcatalog - we'll deploy this on the VM
kubectl delete svc productcatalogservice; kubectl delete deployment productcatalogservice
kubectl delete serviceentry whitelist-egress-google-metadata
kubectl delete serviceentry whitelist-egress-googleapis