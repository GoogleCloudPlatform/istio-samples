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

# set vars
PROJECT_ID="${PROJECT_ID:?PROJECT_ID env variable must be specified}"
ISTIO_VERSION=${ISTIO_VERSION:=1.3.2}
ZONE="us-central1-b"
CLUSTER_NAME="mesh-exp-gke"
CTX="gke_${PROJECT_ID}_${ZONE}_${CLUSTER_NAME}"


# configure cluster context
gcloud config set project $PROJECT_ID
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
kubectl config use-context $CTX

# set up istio permissions
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"

# get latest Istio
log "Downloading Istio ${ISTIO_VERSION}..."
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

# install the istio control plane via helm
log "Installing CRDs to the GKE cluster..."
for i in istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
cat istio-${ISTIO_VERSION}/install/kubernetes/namespace.yaml > scripts/istio.yaml

helm template istio-${ISTIO_VERSION}/install/kubernetes/helm/istio --name istio \
--namespace istio-system \
--set prometheus.enabled=true \
--set kiali.enabled=true --set kiali.createDemoSecret=true \
--set "kiali.dashboard.jaegerURL=http://jaeger-query:16686" \
--set "kiali.dashboard.grafanaURL=http://grafana:3000" \
--set grafana.enabled=true \
--set global.meshExpansion.enabled=true >> scripts/istio.yaml

kubectl apply -f scripts/istio.yaml


log "...Success."