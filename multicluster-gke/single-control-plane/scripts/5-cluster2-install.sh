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


# Create templated manifests using Cluster 1's Control Plane info, for deployment into
# Cluster 2
kubectl config use-context $ctx1

export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')

log "Pilot: $PILOT_POD_IP"
log "Istio-Policy (mixer): $POLICY_POD_IP"
log "Istio-Telemetry (mixer): $TELEMETRY_POD_IP"

HELM_DIR="istio-${ISTIO_VERSION}/install/kubernetes/helm/istio"
 helm template $HELM_DIR \
  --namespace istio-system --name istio-remote \
  --values $HELM_DIR/values-istio-remote.yaml \
  --set global.remotePilotAddress=${PILOT_POD_IP} \
  --set global.remotePolicyAddress=${POLICY_POD_IP} \
  --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} > istio-remote.yaml

# Deploy the templated Istio components onto cluster-2
kubectl config use-context $ctx2
kubectl create namespace istio-system
kubectl apply -f istio-remote.yaml
kubectl label namespace default istio-injection=enabled

