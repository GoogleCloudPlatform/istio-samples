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



# Cluster 1 gets:
log "☸️ Creating productcatalog-gke Istio resources on cluster1..."
# productcatalog-gke serviceentry


# productacatalog DR --> VM, GKE subsets


# productcatalogservice VS --> 100% VM, 0% GKE



# Cluster 2 gets:

# productcatalog-gke deployment
log "🛍 Deploying productcatalog-gke on cluster2..."

# local productcatalog-gke service


# productacatalog DR --> VM, GKE subsets
log "☸️ Creating productcatalog-gke Istio resources on cluster2..."



# productcatalogservice VS --> 100% VM, 0% GKE

