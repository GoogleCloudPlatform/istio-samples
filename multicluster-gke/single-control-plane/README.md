# Demo: Multicluster Istio- Single Control Plane

This demo shows how to use Istio to orchestrate [an application](https://github.com/GoogleCloudPlatform/microservices-demo) running across two Google
Kubernetes Engine clusters in the same project, but across two different [zones](https://cloud.google.com/compute/docs/regions-zones/#identifying_a_region_or_zone).

![topology](screenshots/topology.png)

### Prerequisites

1. a GCP project with Billing enabled.
2. gcloud
3. kubectl
4. [helm CLI](https://github.com/helm/helm/releases), installed wherever you're running
   these commands (Google Cloud shell, laptop,
   etc.) Note that we are only using the `helm template` command in this demo (ie. [Tiller](https://helm.sh/docs/glossary/#tiller)
   not required on any of the Kubernetes clusters).

## 1 - Create two GKE clusters

Set the project ID to your GCP Project:

```
export PROJECT_ID=<your-GCP-project-ID>
```

Then run the script to create two GKE clusters in your project:

```
./scripts/1-cluster-create.sh
```

Then, run:

```
watch -n 1 gcloud container clusters list
```

Wait for both clusters to be `RUNNING`.

## 2 - Connect to clusters

This script creates kubeconfigs for both clusters, to allow future `kubectl` commands to
switch back and forth between them.

```
./scripts/2-get-credentials.sh
```

## 3 - Create a GKE Firewall Rule

This step allows pods on both clusters to communicate directly.

```
./scripts/3-firewall.sh
```


## 4 - Install the Istio Control Plane on Cluster 1

This step installs the Istio control plane on one of the GKE clusters.

```
./scripts/4-cluster1-install.sh
```


## 5 - Install the Istio Remote on Cluster 2

Now we'll install the remote Istio components (Citadel's node-agent, and an Envoy sidecar injector) on Cluster 2.

```
./scripts/5-cluster2-install.sh
```


## 6 - Connect Cluster 2 to Cluster 1

This step generates a [Kubeconfig](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#define-clusters-users-and-contexts) file for the remote Cluster 2, then adds it as a [Secret](https://kubernetes.io/docs/concepts/configuration/secret/)
to Cluster 1.

```
./scripts/6-connect-clusters.sh
```


## 7 - Deploy [Hipstershop](https://github.com/GoogleCloudPlatform/microservices-demo)

This script deploys the sample application across both cluster 1 and cluster 2. We have
split the microservices in the application so that some run centrally to the Istio control
plane (cluster 1), and the rest run on the remote Istio cluster (cluster 2):

![topology](screenshots/topology.png)


Run the script to deploy:

```
./scripts/7-deploy-hipstershop.sh
```

You can verify that the deployment was successful using 3 methods:


1) Run `kubectl get pods` on both clusters to ensure all pods are `RUNNING` and `READY`.

2) From cluster-1, run `istioctl proxy-status`. You should see cluster-2 services (eg.
   `cartservice`) appear in the list. This means that the Istio control plane can
   successfully configure Envoy proxies running on the remote GKE cluster-2.

```
PROXY                                                  CDS        LDS        EDS               RDS          PILOT                            VERSION
adservice-6cd6965787-djp8r.default                     SYNCED     SYNCED     SYNCED (50%)      SYNCED       istio-pilot-7d7c547f8b-9jh24     1.1.1
cartservice-57c6949b9-qbfqx.default                    SYNCED     SYNCED     SYNCED (50%)      SYNCED       istio-pilot-7d7c547f8b-9jh24     1.1.1
checkoutservice-6848667dd7-b4qf6.default               SYNCED     SYNCED     SYNCED (50%)      SYNCED       istio-pilot-7d7c547f8b-9jh24     1.1.1
currencyservice-668f49f985-lbcfh.default               SYNCED     SYNCED     SYNCED (50%)      SYNCED       istio-pilot-7d7c547f8b-9jh24     1.1.1
```

3) open Hipstershop in the browser by getting the Istio `IngressGateway`'s `EXTERNAL_IP`:

```
kubectl get svc istio-ingressgateway -n istio-system
```

From the frontend, click on a product. You should see product recommendations, and be able to navigate to your Cart without any errors:

![browser-screenshot](screenshots/browser-screenshot.png)

This means that the Hipstershop Frontend service (running in cluster 1) was able to use
its Istio sidecar proxy to resolve DNS to Kubernetes Services running in cluster 2.

🎉 Well done! You just orchestrated an application with Istio across multiple Google
Kubernetes Engine
clusters.

## Cleanup

To fully delete all the GCP resources used in this demo:

```
./scripts/cleanup-delete-cluster.sh
```

To remove the Hipstershop app, but keep both GKE clusters (and Istio) running:

```
./scripts/cleanup-hipstershop-only.sh
```

## What's next?

Now that you have Istio installed on two clusters, you can create [traffic rules](https://github.com/GoogleCloudPlatform/istio-samples/tree/master/istio-canary-gke) and [security policies](https://github.com/GoogleCloudPlatform/istio-samples/tree/master/security-intro) that
span both clusters.

Or to deploy the BookInfo app with multicluster Istio, [see the Istio documentation](https://preliminary.istio.io/docs/examples/multicluster/gke/).
