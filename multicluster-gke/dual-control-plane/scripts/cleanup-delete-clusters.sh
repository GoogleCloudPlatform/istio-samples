#!/usr/bin/env bash

# Copyright 2019 Google LLC
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
log() { echo "$1" >&2; }

# set vars
ZONE="us-central1-b"

PROJECT_1="${PROJECT_1:?PROJECT_1 env variable must be specified}"
CLUSTER_1="dual-cluster1"

PROJECT_2="${PROJECT_2:?PROJECT_2 env variable must be specified}"
CLUSTER_2="dual-cluster2"

log "Deleting cluster 1..."
gcloud config set project $PROJECT_1
gcloud container clusters delete $CLUSTER_1 --zone $ZONE

# Project 2 - Create GKE Cluster 2
log "Deleting cluster 2..."
gcloud config set project $PROJECT_2
gcloud container clusters delete $CLUSTER_2 --zone $ZONE
