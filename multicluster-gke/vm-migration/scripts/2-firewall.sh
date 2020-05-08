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


# Cluster 1 --> VM
log "🔥 Creating firewall rules..."
export CLUSTER_1_POD_CIDR=$(gcloud container clusters describe ${CLUSTER_1_NAME?} --zone ${CLUSTER_1_ZONE?} --format=json | jq -r '.clusterIpv4Cidr')
log "Cluster 1 Pod CIDR is ${CLUSTER_1_POD_CIDR}"

gcloud compute firewall-rules create "${CLUSTER_1_NAME}-to-${GCE_INSTANCE_NAME}" \
--source-ranges=$CLUSTER_1_POD_CIDR \
--target-tags=${GCE_INSTANCE_NAME} \
--action=ALLOW \
--rules=tcp:${SERVICE_PORT_NUMBER}

# Cluster 2 --> VM
export CLUSTER_2_POD_CIDR=$(gcloud container clusters describe ${CLUSTER_2_NAME?} --zone ${CLUSTER_2_ZONE?} --format=json | jq -r '.clusterIpv4Cidr')
log "Cluster 2 Pod CIDR is ${CLUSTER_2_POD_CIDR}"
gcloud compute firewall-rules create "${CLUSTER_2_NAME}-to-${GCE_INSTANCE_NAME}" \
--source-ranges=$CLUSTER_2_POD_CIDR \
--target-tags=${GCE_INSTANCE_NAME} \
--action=ALLOW \
--rules=tcp:${SERVICE_PORT_NUMBER}


log "✅ done"