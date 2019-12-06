# Geo-aware Multicluster Load-Balancing with Istio on GKE
- [Geo-aware Multicluster Load-Balancing with Istio on GKE](#geo-aware-multicluster-load-balancing-with-istio-on-gke)
  - [Introduction](#introduction)
  - [Prerequistes](#prerequistes)
  - [Setup](#setup)
  - [Install Istio](#install-istio)
  - [Deploy the Sample App](#deploy-the-sample-app)
  - [Create Multicluster Ingress](#create-multicluster-ingress)
  - [Verify Multicluster Ingress](#verify-multicluster-ingress)
  - [Test Geo-Aware Load Balancing](#test-geo-aware-load-balancing)
  - [Cleanup](#cleanup)


## Introduction

This sample demonstrates how to configure an HTTP(S) Load Balancer, combined with an GCP static IP, to route client requests to the closest Istio cluster. We will end up with the following setup. `ZonePrinter` is the sample app, fronted by three Istio IngressGateways running in three clusters:

![arch](images/architecture.png)

See the accompanying [blog post](https://askmeegs.dev/istio-multicluster-ingress) for more background.

## Prerequistes

- One [GCP Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with Billing enabled
- [GCE, Container APIs enabled](https://cloud.google.com/apis/docs/getting-started#enabling_apis)
- [gcloud](https://cloud.google.com/sdk/install) SDK on your local machine
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) on your local machine

## Setup

First, set your project ID:

```
export PROJECT_ID="<your-project-id>"
```

Ensure gcloud is authenticated to your account

```
gcloud auth login
gcloud auth application-default login
```

Then, run the script to create three GKE clusters in the `us-east`, `us-west`, and `europe-west` regions:

```
./1-create-clusters.sh
```

Wait for all three clusters to be `RUNNING`:

```
watch gcloud container clusters list
```

After a few minutes, you should see:

```

NAME      LOCATION        MASTER_VERSION  MASTER_IP      MACHINE_TYPE   NODE_VERS
ION   NUM_NODES  STATUS
cluster3  europe-west2-b  1.14.8-gke.12   <IP>  n1-standard-4  1.14.8-gk
e.12  3          RUNNING
cluster2  us-east4-a      1.14.8-gke.12   <IP>  n1-standard-4  1.14.8-gk
e.12  3          RUNNING
cluster1  us-west2-a      1.14.8-gke.12   <IP>  n1-standard-4  1.14.8-gk
e.12  3          RUNNING
```

## Install Istio

Install the Istio control plane on all three clusters. Note that each cluster operates separately, and Multicluster Istio is not enabled.

```
./2-install-istio.sh
```

## Deploy the Sample App

Deploy the ZonePrinter application to all three clusters. This application is a simple web server that prints the GKE Region/Zone it's running in.

This script creates a Kubernetes Deployment with one replica, one Service (type `ClusterIP`), and two Istio resources: a `Gateway` (punching port `80` into the default IngressGateway), and a `VirtualService`, routing inbound requests through the Gateway on port 80, to the `zone-printer` Service.

```
./3-deploy-app.sh
```

Note that right now (and by default), the Istio IngressGateway is mapped to a service type `LoadBalancer`, and has its own separate public IP. We can separately call that IngressGateway IP on all three clusters to verify that the zone printer app is running:

```
./4-verify-app.sh
```

You should see HTML output for each cluster, including reports from three separate regions:

```
	<h1>us-west2-a!</h1>
...
	<h1>Ashburn, Virginia, USA</h1>
...
    <h1>London, U.K.</h1>
```

## Create Multicluster Ingress

Now we're ready to put a global IP in front of each Istio IngressGateway, to enable geo-aware anycast routing.

```
./5-create-ingress.sh
```

This script does the following:
1. Creates a VirtualService on all three clusters, to set up health checking for the IngressGateway. [This is needed](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#health_checks) for GCP load balancer health checking. Because the IngressGateway already exposes a `/healthz` endpoint on port `15020`, we just have to do a URL rewrite for requests from the `GoogleHC` user-agent.
2. Updates the Service type on the Istio IngressGateway on all three clusters, from `LoadBalancer` to `NodePort`. A NodePort service is needed to configure Ingress.
3. Reserves a global static IP, `zoneprinter-ip`.
4. Installs [`kubemci`](https://github.com/GoogleCloudPlatform/k8s-multicluster-ingress), then uses it to provision a multicluster Ingress, mapping to the three clusters. The `kubemci create` command takes in a Kubernetes Ingress resource (see `ingress/ingress.yaml`), which has `annotations` for `gce-multi-cluster`, and a reference to the name of our new global static IP. The Ingress backend is the `istioingressgateway` Service running on port 80. From here, the `kubemci` tool provisions a GCP HTTP(S) Load Balancer, including backend services, url mappings, and firewall rules.

## Verify Multicluster Ingress

Verify that the multicluster ingress was created, by running `kubemci list`. You should see:

```
NAME                  IP             CLUSTERS
zoneprinter-ingress   <your-global-IP>   cluster1, cluster2, cluster3
```

Then, run:

```
kubemci get-status zoneprinter-ingress --gcp-project=${PROJECT_ID}
```

You should see:
```
Load balancer zoneprinter-ingress has IPAddress <ip> and is spread across 3 clusters (cluster1,cluster2,cluster3)
```


## Test Geo-Aware Load Balancing

Now that we've configure multicluster ingress for a global anycast IP, we should be able to access the global IP from clients around the world,and be routed to the ZonePrinter running in the closest GKE cluster.

For instance, from a laptop connected to a home network on the East Coast, navigated to the global IP in a browser, we're routed to the `us-east4-a` cluster. Refreshing the page, we continue to see the same region.

![](images/browser.png)

To test the geo-aware routing further, you can create Google Compute Engine instances in different regions, ssh into each one, and `curl` the global IP. For instance, a VM in the Netherlands (`europe-west4-a`) is routed to the London (`europe-west2-b`) cluster:

```
mokeefe@netherlands-client:~$ curl 34.102.158.9
<!DOCTYPE html>
                <h4>Welcome from Google Cloud datacenters at:</h4>
                <h1>London, U.K.</h1>
                <h3>You are now connected to &quot;europe-west2-b&quot;</h3>
                <img src="https://upload.wikimedia.org/wikipedia/en/a/ae/Flag_of_the_United_Kingdom.svg" style="wid
th: 640px; height: auto; border: 1px solid black"/>
```

And an instance in Oregon (`us-west1-b`) is routed to the Los Angeles (`us-west2-a`) cluster:

```
mokeefe@oregon-client:~$  curl 34.102.158.9
<!DOCTYPE html>
                <h4>Welcome from Google Cloud datacenters at:<h4>
                <h1>us-west2-a!</h1>
```

🎊 Well done! You just set up geo-aware load balancing for Istio services running in three GKE clusters, across three regions.

## Cleanup

To delete the resources used in this sample (ingress, static IP, GKE clusters):

```
./6-cleanup.sh
```