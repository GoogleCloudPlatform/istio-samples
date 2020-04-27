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

export ISTIOD_REMOTE_EP=$(kubectl --context=${ctx1} -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
log "ISTIOD_REMOTE_EP is ${ISTIOD_REMOTE_EP}"

kubectl config use-context $ctx2

sed -i -e 's/\ISTIOD_REMOTE_EP/'${ISTIOD_REMOTE_EP}'/g' istio-remote-cluster.yaml

cd ../../common
INSTALL_YAML="../multicluster-gke/single-control-plane/istio-remote-cluster.yaml" ./install_istio.sh

cd istio-1.5.2/
kubectl create secret generic cacerts -n istio-system \
    --from-file=samples/certs/ca-cert.pem \
    --from-file=samples/certs/ca-key.pem \
    --from-file=samples/certs/root-cert.pem \
    --from-file=samples/certs/cert-chain.pem

cd ../../multicluster-gke/single-control-plane/

