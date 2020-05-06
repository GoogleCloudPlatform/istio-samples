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

log "🚦 Sending 100% of productcatalog traffic to GKE..."

kubectl config use-context ${CTX_1}
kubectl apply -f productcatalog-gke/vs-100-cluster1.yaml

kubectl config use-context ${CTX_2}
kubectl apply -f productcatalog-gke/vs-100-cluster2.yaml
log "⭐️ GKE migration complete ☸️"
