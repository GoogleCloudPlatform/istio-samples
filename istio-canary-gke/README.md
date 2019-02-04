# ProductCatalog Canary Deployment (GKE / Istio)

This example demonstrates how to use [Istio’s](https://istio.io/) [Traffic Splitting](https://istio.io/docs/concepts/traffic-management/#splitting-traffic-between-versions) feature to perform a Canary deployment on [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/).

In this sample, `productcatalogservice-v2` introduces a 3-second
[latency](https://github.com/GoogleCloudPlatform/microservices-demo/tree/master/src/productcatalogservice#latency-injection) into all server requests. We’ll show how to use Stackdriver and Istio together to
view the latency difference between the existing `productcatalog` deployment and the
slower v2 deployment.

  - [Setup](#setup)
  - [Deploy the Sample App](#deploy-the-sample-app)
  - [Deploy ProductCatalog v2](#deploy-productcatalog-v2)
  - [Observe Latency with Stackdriver](#observe-latency-with-stackdriver)
  - [Rollback](#rollback)
  - [Cleanup](#cleanup)
  - [Learn More](#learn-more)


## Setup

1. Navigate to the [Google Cloud Console](https://console.cloud.google.com/), and [create a new project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) (or navigate to an
   existing project).
2. On the top right of the Cloud Console, click "Activate Cloud Shell."

![activate cloud shell](screenshots/activate-shell.png)

3. Enable the Kubernetes Engine API.

```
gcloud services enable container.googleapis.com
```

4. Create a GKE cluster using [Istio on GKE](https://cloud.google.com/istio/docs/istio-on-gke/overview). This add-on will provision
   your GKE cluster with Istio.

```
gcloud beta container clusters create istio-demo \
    --addons=Istio --istio-config=auth=MTLS_PERMISSIVE \
    --zone=us-central1-f \
    --machine-type=n1-standard-2 \
    --num-nodes=4
```
5. Once the cluster is ready, ensure that Istio is running:

```
$ kubectl get pods -n istio-system

NAME                                     READY     STATUS      RESTARTS   AGE
istio-citadel-776fb85794-9gcqz           1/1       Running     0          7m
istio-cleanup-secrets-cg9b4              0/1       Completed   0          7m
istio-egressgateway-7f778c7fcf-hj9fw     1/1       Running     0          7m
istio-galley-794f98cf5f-9867s            1/1       Running     0          7m
istio-ingressgateway-56b648f9fb-mt7tb    1/1       Running     0          7m
istio-pilot-d87948784-7kfzt              2/2       Running     0          7m
istio-policy-5757c77d8f-54vsl            2/2       Running     0          7m
istio-security-post-install-bqjqq        0/1       Completed   0          7m
istio-sidecar-injector-f555db659-l5btv   1/1       Running     0          7m
istio-telemetry-85c84d85c6-qdtnm         2/2       Running     0          7m
prometheus-7c589d4989-9mgg8              2/2       Running     1          7m
```

## Deploy the Sample App

1. Clone the manifests for this demo.
```
git clone https://github.com/GoogleCloudPlatform/istio-samples.git; cd istio-samples/istio-canary-gke;
```
2. Label the default namespace for Istio [sidecar auto-injection](https://istio.io/docs/setup/kubernetes/sidecar-injection/):

```
kubectl label namespace default istio-injection=enabled
```

3. Deploy the [microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) application using the YAML files provided in this repo.

```
kubectl apply -f ./hipstershop
```

4. Using `kubectl get pods`, verify that all pods are `Running` and `Ready`.

At this point, ProductCatalog v1 is deployed to the cluster, along with the rest of the
demo microservices. You can reach the Hipstershop frontend at the `EXTERNAL_IP` address
output for this command:

```
kubectl get svc -n istio-system istio-ingressgateway
```

## Deploy ProductCatalog v2

1. Create an Istio [DestinationRule](https://istio.io/docs/reference/config/istio.networking.v1alpha3/#DestinationRule) for `productcatalogservice`.

```
kubectl apply -f canary/destinationrule.yaml
```

2. Deploy `productcatalog` v2.
```
kubectl apply -f canary/productcatalog-v2.yaml
```

3. Using `kubectl get pods`, verify that the `v2` pod is Running.
```
productcatalogservice-v2-79459dfdff-6qdh4   2/2       Running   0          1m
```

4. Create an Istio [VirtualService](https://istio.io/docs/reference/config/istio.networking.v1alpha3/#VirtualService) to split incoming `productcatalog` traffic between v1 (75%) and v2 (25%).
```
kubectl apply -f canary/vs-split-traffic.yaml
```

5. In a web browser, navigate again to the hipstershop frontend.
6. Refresh the homepage a few times. You should notice that periodically, the frontend is
   slower to load. Let's explore ProductCatalog's latency with Stackdriver.

## Observe Latency with Stackdriver

1. Navigate to [Stackdriver Monitoring](https://app.google.stackdriver.com).
2. Create a Stackdriver Workspace for your GCP project
   ([instructions](https://cloud.google.com/monitoring/workspaces/guide#single-project-ws)).
3. From your new Stackdriver Workspace, navigate to **Resources > Metrics Explorer.** in the
   left sidebar.

![stackdriver sidebar](screenshots/stackdriver-sidebar.png)


4. From Metrics Explorer, enter the following parameters on the left side of the window:
	- **Resource type**: Kubernetes Container
	- **Metric**: Server Response Latencies (`istio.io/service/server/response_latencies`)
	- **Group by**: `destination_workload_name`
	- **Aligner**: 50th percentile
	- **Reducer**: mean
	- **Alignment period**: 1 minute

5. In the menubar of the chart on the right, choose the **Line** type.
6. Once the latency chart renders, you should see `productcatalog-v2` as an outlier, with
    mean latencies hovering at 3 seconds. This is the value of `EXTRA_LATENCY` we injected into v2.

![metrics explorer](screenshots/metrics-explorer.png)

You’ll also notice that other services (such as `frontend`) have an irregular latency spike. This is because the [frontend relies on](https://github.com/GoogleCloudPlatform/microservices-demo#service-architecture) ProductCatalog, for which 25% of requests are routing through the slower `v2` deployment.

![v2 latency](screenshots/v2-latency.png)

## Rollback

1. Return 100% of `productcatalog` traffic to `v1`:
```
kubectl apply -f canary/rollback.yaml
```
2. Finally, remove `v2`:
```
kubectl delete -f canary/productcatalog-v2.yaml
```

## Cleanup

To avoid incurring additional billing costs, delete the GKE cluster.

```
gcloud container clusters delete istio-demo --zone us-central1-f
```

## Learn More

- [Incremental Istio Part 1, Traffic
  Management](https://istio.io/blog/2018/incremental-traffic-management/) (Istio blog)
- [Canary Deployments using Istio](https://istio.io/blog/2017/0.1-canary/)  (Istio blog)
- [Drilling down into Stackdriver Service
  Monitoring](https://cloud.google.com/blog/products/gcp/drilling-down-into-stackdriver-service-monitoring)
  (GCP blog)
