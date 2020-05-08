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
gcloud config set project $PROJECT_ID

cluster1="cluster1"
cluster2="cluster2"
network1="network1"
cluster1zone="us-east1-b"
cluster2zone="us-central1-b"

ctx1="gke_${PROJECT_ID}_${cluster1zone}_cluster-1"
ctx2="gke_${PROJECT_ID}_${cluster2zone}_cluster-2"

ISTIO_VERSION=${ISTIO_VERSION:=1.5.2}

services1=("emailservice" "paymentservice" "shippingservice" "adservice" "checkoutservice" "currencyservice" "frontend" "productcatalogservice")
services2=("loadgenerator" "cartservice" "recommendationservice" "redis-cart")