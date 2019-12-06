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

source ./common.sh

install_istio() {
    kubectx $1

    kubectl create namespace istio-system

    kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)

    helm template ${WORKDIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
    sleep 20

    kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

    sleep 1

    helm template ${WORKDIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio --name istio --namespace istio-system \
    --set prometheus.enabled=true \
    --set tracing.enabled=true \
    --set kiali.enabled=true --set kiali.createDemoSecret=true \
    --set "kiali.dashboard.jaegerURL=http://jaeger-query:16686" \
    --set "kiali.dashboard.grafanaURL=http://grafana:3000" \
    --set grafana.enabled=true \
    --set global.proxy.accessLogFile="/dev/stdout" \
    --set mixer.policy.enabled=false > istio.yaml

    # install istio
    kubectl apply -f istio.yaml
}

# Download Istio 1.4
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -


# Configure kubectx / install Istio
for svc in "${CLUSTERS[@]}" ; do
    NAME="${svc%%:*}"
    ZONE="${svc##*:}"

    gcloud container clusters get-credentials ${NAME} --zone ${ZONE} --project ${PROJECT_ID}

    # rename ctx
    LONG_CTX="gke_${PROJECT_ID}_${ZONE}_${NAME}"
    kubectx ${NAME}=${LONG_CTX}

    # install istio on each cluster
    # install_istio $NAME
done

