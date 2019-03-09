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

# Creates two GKE clusters in different regions.

set -euo pipefail

log() { echo "$1" >&2; }

PROJECT_ID="${PROJECT_ID:?PROJECT_ID env variable must be specified}"
cluster1zone="us-east1-b"
cluster2zone="us-central1-b"

gcloud config set project $PROJECT_ID

log "Deleting cluster1..."
gcloud container clusters delete cluster-1 --zone $cluster1zone

log "Deleting cluster2..."
gcloud container clusters delete cluster-2 --zone $cluster2zone
