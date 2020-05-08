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

# Deploy "most of" Hipstershop to cluster 1
kubectl config use-context $ctx1
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml
kubectl delete svc frontend-external
# delete cluster2 svcs from cluster1
for i in "${services2[@]}"
do
   echo "Deleting ${i} from ${ctx1}"
   kubectl delete deployment $i
done


# Deploy the rest of Hipstershop (cartservice, rediscart, recommendations, loadgenerator) to cluster2
kubectl config use-context $ctx2
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml
kubectl delete svc frontend-external
# delete cluster1 svcs from cluster2
for i in "${services1[@]}"
do
   echo "Deleting ${i} from ${ctx2}"
   kubectl delete deployment $i
done
