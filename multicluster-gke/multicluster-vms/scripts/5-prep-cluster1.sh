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

# Cluster 1 will oversee the proxy config for istio-gce
# (but both clusters 1 and 2 will be configured to reach the VM service)
log "📦 Getting cluster 1's info to send to the VM..."

# Generate cluster.env
kubectl config set-context ${CTX_1}
export ISTIOD_IP=$(kubectl get -n istio-system service istiod -o jsonpath='{.spec.clusterIP}')
log "⛵️ cluster1 istiod IP is $ISTIOD_IP"

ISTIO_SERVICE_CIDR=$(gcloud container clusters describe $CLUSTER_1_NAME --zone $CLUSTER_1_ZONE --project $PROJECT_ID --format "value(servicesIpv4Cidr)")
echo -e "ISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env
echo "ISTIO_INBOUND_PORTS=3550,8080" >> cluster.env

# client certs
log "Getting client certs..."
go run istio.io/istio/security/tools/generate_cert -client -host spiffee://cluster.local/vm/vmname \
 --out-priv key.pem --out-cert cert-chain.pem  -mode self-signed

# root cert
log "Getting root cert..."
kubectl -n istio-system get cm istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' > root-cert.pem
