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

# NOTE - if you are on a mac and you don't have gsed, uncomment this line:
#  brew install gnu-sed

# vars
PROJECT_ID="${PROJECT_ID:?PROJECT_ID env variable must be specified}"
export VM_NAME="istio-gce"
ZONE="us-central1-b"
CLUSTER_NAME="mesh-exp-gke"
export SERVICE_NAMESPACE="default" # put VM-based ProductCatalog's istio services in the GKE default ns
CTX="gke_${PROJECT_ID}_${ZONE}_${CLUSTER_NAME}"

# configure cluster context
gcloud config set project $PROJECT_ID
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
kubectl config use-context $CTX

# generate cluster.env from the GKE cluster
GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

ISTIO_SERVICE_CIDR=$(gcloud container clusters describe ${CLUSTER_NAME?} \
                       --zone ${ZONE?} --project ${PROJECT_ID?} \
                       --format "value(servicesIpv4Cidr)")
echo $ISTIO_SERVICE_CIDR

log "istio CIDR is: ${ISTIO_SERVICE_CIDR}"

echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" | tee scripts/cluster.env
echo "ISTIO_INBOUND_PORTS=8080" >> scripts/cluster.env


# Get istio control plane certs
kubectl -n ${SERVICE_NAMESPACE?} get secret istio.default \
  -o jsonpath='{.data.root-cert\.pem}' | base64 --decode | tee scripts/root-cert.pem
kubectl -n ${SERVICE_NAMESPACE?} get secret istio.default \
  -o jsonpath='{.data.key\.pem}' | base64 --decode | tee scripts/key.pem
kubectl -n ${SERVICE_NAMESPACE?} get secret istio.default \
  -o jsonpath='{.data.cert-chain\.pem}' | base64 --decode | tee scripts/cert-chain.pem

# Populate 7-configure-mesh script with the GWIP IP
# (this script is sent to the VM, to run there.)
pattern='GWIP=""'
replace="GWIP='$GWIP'"
gsed -r -i "s|$pattern|$replace|g" scripts/7-configure-vm.sh

# scp certs, env file, and script to the GCE instance
log "sending cluster.env, certs, and script to VM..."
# scp everything over to the VM
gcloud compute --project ${PROJECT_ID?} scp --zone ${ZONE?} \
  scripts/7-configure-vm.sh scripts/cluster.env scripts/*.pem ${VM_NAME?}:
log "...done."
