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
ISTIO_VERSION=${ISTIO_VERSION:=1.4.2}
ZONE="us-central1-b"
CLUSTER_NAME="mesh-exp-gke"
CTX="gke_${PROJECT_ID}_${ZONE}_${CLUSTER_NAME}"

GCE_INSTANCE_NAME="istio-gce"
GCE_IP=$(gcloud compute instances describe $GCE_INSTANCE_NAME --zone $ZONE --format=text  | grep '^networkInterfaces\[[0-9]\+\]\.networkIP:' | sed 's/^.* //g' 2>&1)
log "GCE instance: $GCE_INSTANCE_NAME --IP is: $GCE_IP"

SERVICE_NAMESPACE="default"
SVC_NAME="productcatalogservice"
PRODUCTCATALOG_PORT="3550"

# configure cluster context
gcloud config set project $PROJECT_ID
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
kubectl config use-context $CTX

# register VM with GKE istio
./istio-${ISTIO_VERSION}/bin/istioctl register $SVC_NAME $GCE_IP "grpc:${PRODUCTCATALOG_PORT}"

# output result of registration
kubectl get endpoints $SVC_NAME -o yaml

# add a ServiceEntry for ProductCatalog
kubectl apply -n default -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: ${SVC_NAME}
spec:
  hosts:
  - ${SVC_NAME}.default.svc.cluster.local
  location: MESH_INTERNAL
  ports:
  - number: 3550
    name: grpc
    protocol: GRPC
  resolution: STATIC
  endpoints:
  - address: ${GCE_IP}
    ports:
      grpc: 3550
    labels:
      app: ${SVC_NAME}
EOF
