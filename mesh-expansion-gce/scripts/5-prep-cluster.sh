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
ZONE="us-central1-b"
CLUSTER_NAME="mesh-exp-gke"
CTX="gke_${PROJECT_ID}_${ZONE}_${CLUSTER_NAME}"
GCE_INSTANCE_NAME="istio-gce"
SERVICE_NAMESPACE="default"

# Generate cluster.env
export ISTIOD_IP=$(kubectl get -n istio-system service istiod -o jsonpath='{.spec.clusterIP}')
log "⛵️ istiod IP is $ISTIOD_IP"

ISTIO_SERVICE_CIDR=$(gcloud container clusters describe $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID --format "value(servicesIpv4Cidr)")
echo -e "ISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env
echo "ISTIO_INBOUND_PORTS=3550,8080" >> cluster.env

# client certs
log "Getting client certs..."
go run istio.io/istio/security/tools/generate_cert -client -host spiffee://cluster.local/vm/vmname \
 --out-priv key.pem --out-cert cert-chain.pem  -mode self-signed

# root cert
log "Getting root cert..."
kubectl -n istio-system get cm istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' > root-cert.pem
