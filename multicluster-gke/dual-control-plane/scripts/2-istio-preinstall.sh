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

preinstall_istio () {
    kubectl create namespace istio-system
    kubectl apply -f istio-${ISTIO_VERSION}/install/kubernetes/helm/helm-service-account.yaml
    helm init --wait --service-account tiller

    kubectl create secret generic cacerts -n istio-system \
        --from-file=istio-${ISTIO_VERSION}/samples/certs/ca-cert.pem \
        --from-file=istio-${ISTIO_VERSION}/samples/certs/ca-key.pem \
        --from-file=istio-${ISTIO_VERSION}/samples/certs/root-cert.pem \
        --from-file=istio-${ISTIO_VERSION}/samples/certs/cert-chain.pem
    helm install istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
}

# set vars
ZONE="us-central1-b"
ISTIO_VERSION=${ISTIO_VERSION:=1.4.2}

PROJECT_1="${PROJECT_1:?PROJECT_1 env variable must be specified}"
CLUSTER_1="dual-cluster1"
CTX_1="gke_${PROJECT_1}_${ZONE}_${CLUSTER_1}"

PROJECT_2="${PROJECT_2:?PROJECT_2 env variable must be specified}"
CLUSTER_2="dual-cluster2"
CTX_2="gke_${PROJECT_2}_${ZONE}_${CLUSTER_2}"

log "Downloading Istio ${ISTIO_VERSION}..."
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

# Cluster 1
log "Setting up Cluster 1..."
gcloud config set project $PROJECT_1
gcloud container clusters get-credentials $CLUSTER_1 --zone $ZONE
kubectl config use-context $CTX_1
preinstall_istio
log "...done with cluster 1."

# Cluster 2
log "Setting up Cluster 2..."
gcloud config set project $PROJECT_2
gcloud container clusters get-credentials $CLUSTER_2 --zone $ZONE
kubectl config use-context $CTX_2
preinstall_istio
log "...done with cluster 2."