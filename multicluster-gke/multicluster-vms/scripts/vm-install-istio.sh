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


# install the sidecar proxy
curl -L https://storage.googleapis.com/istio-release/releases/1.5.1/deb/istio-sidecar.deb > istio-sidecar.deb
sudo dpkg -i istio-sidecar.deb

# update /etc/hosts
echo "${ISTIOD_IP} istiod.istio-system.svc" | sudo tee -a /etc/hosts

# install certs
sudo mkdir -p /etc/certs
sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
sudo mkdir -p /var/run/secrets/istio/
sudo cp root-cert.pem /var/run/secrets/istio/

# install cluster.env
sudo cp cluster.env /var/lib/istio/envoy

# transfer file ownership to istio proxy
sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy /var/run/secrets/istio/

# start Istio
sudo systemctl start istio