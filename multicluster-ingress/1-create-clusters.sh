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
gcloud config set project $PROJECT_ID

log "Installing kubectx..."
curl -sLO https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx
chmod +x kubectx
kubectx -h

log "Creating clusters..."
for svc in "${CLUSTERS[@]}" ; do
    NAME="${svc%%:*}"
    ZONE="${svc##*:}"
    gcloud beta container --project ${PROJECT_ID} clusters create ${NAME} --zone ${ZONE} \
    --no-enable-basic-auth --release-channel "regular" --machine-type "n1-standard-4" --image-type "COS" \
    --disk-type "pd-standard" --disk-size "100" \
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    --num-nodes "3" --enable-stackdriver-kubernetes --enable-ip-alias \
    --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing \
    --no-enable-autoupgrade --no-enable-autorepair --async
done