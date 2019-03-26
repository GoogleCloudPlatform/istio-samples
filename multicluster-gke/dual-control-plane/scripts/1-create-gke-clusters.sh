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
CTX_1="gke_${PROJECT_1}_${ZONE}_${CLUSTER_1}"

PROJECT_2="${PROJECT_2:?PROJECT_2 env variable must be specified}"
CLUSTER_2="dual-cluster2"
CTX_2="gke_${PROJECT_2}_${ZONE}_${CLUSTER_2}"

# Project 1 - Create GKE Cluster 1
gcloud config set project $PROJECT_1

 gcloud container clusters create $CLUSTER_1 --zone $ZONE --username "admin" \
  --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
  --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only",\
"https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring",\
"https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly",\
"https://www.googleapis.com/auth/trace.append" \
--num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring  --async


# Project 2 - Create GKE Cluster 2
gcloud config set project $PROJECT_2

gcloud container clusters create $CLUSTER_2 --zone $ZONE --username "admin" \
--machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
--num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --async
