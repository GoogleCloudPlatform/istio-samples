#!/bin/bash

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

# NOTE - THIS SCRIPT SHOULD RUN ON THE GCE INSTANCE, NOT ON YOUR HOST / IN K8s

# set vars
# NOTE - THIS VARIABLE IS AUTO-POPULATED IN ./scripts/4-configure-mesh-exp.sh
# (where GWIP refers to your GKE cluster's Istio IngressGateway IP address)
GWIP=''

# setup --  install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce

# update /etc/hosts for DNS resolution
echo -e "\n$GWIP istio-citadel istio-pilot istio-pilot.istio-system" | \
   sudo tee -a /etc/hosts

# install + run the istio remote - version 1.1.1
curl -L https://storage.googleapis.com/istio-release/releases/1.1.1/deb/istio-sidecar.deb > istio-sidecar.deb

sudo dpkg -i istio-sidecar.deb

ls -ld /var/lib/istio

sudo mkdir -p /etc/certs
sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
sudo cp cluster.env /var/lib/istio/envoy
sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy

ls -l /var/lib/istio/envoy/envoy_bootstrap_tmpl.json
ls -l /var/lib/istio/envoy/sidecar.env
sudo systemctl start istio


# run productcatalog service
sudo docker run -d -p 3550:3550 gcr.io/google-samples/microservices-demo/productcatalogservice:v0.1.0

