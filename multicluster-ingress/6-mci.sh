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

source ./common.sh

log "Installing kubemci..."
wget https://storage.googleapis.com/kubemci-release/release/latest/bin/darwin/amd64/kubemci
sudo chmod +x ./kubemci

log "Creating static IP..."
gcloud compute addresses create --global zoneprinter-ip

log "Creating multicluster ingress..."
./kubemci create zoneprinter-ingress \
--ingress=manifests/ingress.yaml \
--gcp-project=${PROJECT_ID} \
--kubeconfig=${KUBECONFIG}
