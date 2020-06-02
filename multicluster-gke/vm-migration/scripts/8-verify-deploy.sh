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

kubectl config use-context $CTX_1
log "☸️ Cluster 1 pods:"
kubectl get pods

kubectl config use-context $CTX_2
log "☸️ Cluster 2 pods:"
kubectl get pods

log "🕸 Opening Kiali for cluster 2..."
kubectl config use-context $CTX_2
../../common/istio-1.5.2/bin/istioctl dashboard kiali &


log "🚲 Open this frontend IP in a browser:"
kubectl config use-context $CTX_2
kubectl get svc -n istio-system istio-ingressgateway | awk '{print $4}'
