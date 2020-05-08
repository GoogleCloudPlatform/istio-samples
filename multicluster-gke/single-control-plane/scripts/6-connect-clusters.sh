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

# Configure cross cluster service registries
# (let cluster 1 discover services in cluster 2)
cd ../../common/istio-1.5.2/bin
./istioctl x create-remote-secret --context=${ctx2} --name "cluster2" | \
    kubectl apply -f - --context=${ctx1}
cd ../../../multicluster-gke/single-control-plane/