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

log "Deleting cluster 1..."
gcloud container clusters delete $CLUSTER_1 --project $PROJECT_1 --zone $ZONE --async

# Project 2 - Create GKE Cluster 2
log "Deleting cluster 2..."
gcloud config set project $PROJECT_2
gcloud container clusters delete $CLUSTER_2 --project $PROJECT_2 --zone $ZONE --async
