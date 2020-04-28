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

log() { echo "$1" >&2; }
PROJECT_ID="${PROJECT_ID:?PROJECT_ID env variable must be specified}"

# Cluster 1
CLUSTER_1_NAME="cluster1"
CLUSTER_1_ZONE="us-west1-b"
CTX_1="gke_${PROJECT_ID}_${CLUSTER_1_ZONE}_${CLUSTER_1_NAME}"

# Cluster 2
CLUSTER_2_NAME="cluster2"
CLUSTER_2_ZONE="us-east1-b"
CTX_2="gke_${PROJECT_ID}_${CLUSTER_2_ZONE}_${CLUSTER_2_NAME}"

# VM
GCE_INSTANCE_NAME="istio-gce"
GCE_INSTANCE_ZONE="us-central1-b"
SERVICE_NAMESPACE="default"
SERVICE_NAME="productcatalogservice"
SERVICE_PORT_NUMBER="3550"
SERVICE_PORT_PROTOCOL="grpc"