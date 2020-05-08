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

source ./common.sh

# Configure kubectx / install Istio
for svc in "${CLUSTERS[@]}" ; do
    NAME="${svc%%:*}"
    ZONE="${svc##*:}"

    gcloud container clusters get-credentials ${NAME} --zone ${ZONE} --project ${PROJECT_ID}

    # rename ctx
    LONG_CTX="gke_${PROJECT_ID}_${ZONE}_${NAME}"
    kubectx ${NAME}=${LONG_CTX}

    # install istio on each cluster
    cd ../common
    ./install_istio.sh
    cd ../multicluster-ingress
done

