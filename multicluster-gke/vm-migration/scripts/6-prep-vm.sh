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

log "🐳 Setting up the VM and deploying productcatalog..."

# send certs and cluster.env to VM
gcloud compute scp --project=${PROJECT_ID} --zone=${GCE_INSTANCE_ZONE} \
 {key.pem,cert-chain.pem,cluster.env,root-cert.pem,scripts/vm-install-istio.sh,scripts/vm-run-products.sh} ${GCE_INSTANCE_NAME}:

# from the VM, install the Istio sidecar proxy and update /etc/hosts to reach istiod
kubectl config use-context ${CTX_1}
export ISTIOD_IP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
log "⛵️ GWIP is is $ISTIOD_IP"

gcloud compute --project $PROJECT_ID ssh --zone ${GCE_INSTANCE_ZONE} ${GCE_INSTANCE_NAME} --command="ISTIOD_IP=${ISTIOD_IP} ./vm-install-istio.sh"

# from the VM, install Docker and run productcatalog as a docker container
gcloud compute --project $PROJECT_ID ssh --zone ${GCE_INSTANCE_ZONE} ${GCE_INSTANCE_NAME} --command="./vm-run-products.sh"
