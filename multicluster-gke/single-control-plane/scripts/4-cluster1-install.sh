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

# cluster 1 is the "main" cluster running the Istio control plane
# src https://istio.io/docs/setup/install/multicluster/shared/

set -euo pipefail
source ./scripts/env.sh

kubectl config use-context $ctx1
log "Installing the Istio ${ISTIO_VERSION} control plane on ${ctx1} ..."

cd ../../common
INSTALL_YAML="../multicluster-gke/single-control-plane/scripts/cluster1.yaml" ./install_istio.sh
