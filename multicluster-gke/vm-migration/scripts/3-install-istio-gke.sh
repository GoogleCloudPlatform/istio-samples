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

DUAL_VMS_PROFILE="../multicluster-gke/vm-migration/scripts/install.yaml"
cd ../../common

# Cluster 1
log "⛵️ Installing Istio on Cluster 1..."
gcloud config set project $PROJECT_ID
gcloud container clusters get-credentials $CLUSTER_1_NAME --zone $CLUSTER_1_ZONE
kubectl config use-context $CTX_1
INSTALL_YAML=${DUAL_VMS_PROFILE} ./install_istio.sh


# Cluster 2
log "⛵️ Installing Istio on Cluster 2..."
gcloud container clusters get-credentials $CLUSTER_2_NAME --zone $CLUSTER_2_ZONE
kubectl config use-context $CTX_2
INSTALL_YAML=${DUAL_VMS_PROFILE} ./install_istio.sh


# Configure dns
log "🌎 Configuring CoreDNS..."

configure_kubedns () {
     kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"global": ["$(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})"]}
EOF
}

# Cluster 1
log "Configuring DNS on Cluster 1..."
kubectl config use-context $CTX_1
configure_kubedns
log "...done with cluster 1."


# Cluster 2
log "Configuring DNS on Cluster 2..."
kubectl config use-context $CTX_2
configure_kubedns
log "...done with cluster 2."
