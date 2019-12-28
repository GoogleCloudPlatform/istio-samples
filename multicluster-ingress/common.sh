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
log() { echo "$1" >&2; }

if [ -z "$PROJECT_ID" ]
then
    log "You must set PROJECT_ID to continue."
    exit
else
    PROJECT_ID=$PROJECT_ID
fi

export WORKDIR=${WORK_DIR:="${PWD}"}

# 1. los angeles   2. northern virginia    3. london
CLUSTERS=("cluster1:us-west2-a"
        "cluster2:us-east4-a"
        "cluster3:europe-west2-b")

ISTIO_VERSION="1.4.1"

export KUBECONFIG=$WORKDIR/kubeconfig