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

gcloud config set project $PROJECT_ID
gcloud container clusters delete ${CLUSTER_1_NAME} --zone ${CLUSTER_1_ZONE} --quiet --async
gcloud container clusters delete ${CLUSTER_2_NAME} --zone ${CLUSTER_2_ZONE} --quiet --async
gcloud compute --project=$PROJECT_ID instances delete $GCE_INSTANCE_NAME --zone=$GCE_INSTANCE_ZONE