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
#!/bin/bash

# installs standard single-cluster Istio on GKE + the Istio Stackdriver adapter

# Download Istio
WORKDIR="`pwd`"
ISTIO_VERSION="${ISTIO_VERSION:-1.4.2}"
log "Downloading Istio ${ISTIO_VERSION}..."
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -


# Prepare for install
kubectl label namespace default istio-injection=enabled
kubectl create namespace istio-system

kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

helm template ${WORKDIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
sleep 20


# customize
if [ "$ILB_ENABLED" == "true" ]; then
    ILB="--set gateways.istio-ilbgateway.enabled=true"
else
    ILB="--set gateways.istio-ilbgateway.enabled=false"
fi

if [ "$MESH_EXPANSION" == "true" ]; then
    ENABLE_VM="--set global.meshExpansion.enabled=true"
else
    ENABLE_VM="--set global.meshExpansion.enabled=false"
fi


# installs Istio with Envoy access logging enabled
helm template ${WORKDIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio --name istio --namespace istio-system \
--set prometheus.enabled=true \
--set tracing.enabled=true \
--set kiali.enabled=true --set kiali.createDemoSecret=true \
--set "kiali.dashboard.jaegerURL=http://jaeger-query:16686" \
--set "kiali.dashboard.grafanaURL=http://grafana:3000" \
--set grafana.enabled=true \
--set mixer.policy.enabled=false \
${ILB} \
${ENABLE_VM} \
--set global.proxy.accessLogFile="/dev/stdout" >> istio.yaml

# install istio
kubectl apply -f istio.yaml

# install the Stackdriver adapter
git clone https://github.com/istio/installer && cd installer
helm template istio-telemetry/mixer-telemetry --execute=templates/stackdriver.yaml -f global.yaml --set mixer.adapters.stackdriver.enabled=true --namespace istio-system | kubectl apply -f -
cd ..

rm -rf installer/