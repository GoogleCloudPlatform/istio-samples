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

DUAL_PROFILE="../multicluster-gke/dual-control-plane/scripts/install.yaml"
cd ../../common

# Cluster 1
log "Installing Istio on Cluster 1..."
gcloud config set project $PROJECT_1
gcloud container clusters get-credentials $CLUSTER_1 --zone $ZONE
kubectl config use-context $CTX_1
INSTALL_YAML=${DUAL_PROFILE} ./install_istio.sh


# Cluster 2
log "Installing Istio on Cluster 2..."
gcloud config set project $PROJECT_2
gcloud container clusters get-credentials $CLUSTER_2 --zone $ZONE
kubectl config use-context $CTX_2
INSTALL_YAML=${DUAL_PROFILE} ./install_istio.sh

