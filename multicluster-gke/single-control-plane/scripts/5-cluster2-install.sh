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

# configure cluster2 with "remote pilot" to get its config (istiod running in cluster1)
pattern='ISTIOD_REMOTE_EP'
replace="${ISTIOD_REMOTE_EP}"
gsed -r -i "s|$pattern|$replace|g" scripts/cluster2.yaml

# install the istio sidecar injector (istiod), prometheus in cluster2
cd ../../common
INSTALL_YAML="../multicluster-gke/single-control-plane/scripts/cluster2.yaml" ./install_istio.sh

