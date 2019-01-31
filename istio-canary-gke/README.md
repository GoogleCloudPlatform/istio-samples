# ProductCatalog Canary Deployment (GKE / Istio)
This example demonstrates how to use [Istio’s](https://istio.io/) [Traffic Splitting](https://istio.io/docs/concepts/traffic-management/#splitting-traffic-between-versions) feature to perform a Canary deployment on [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/).

In this sample, `productcatalogservice-v2` introduces a 3-second
[latency](https://github.com/GoogleCloudPlatform/microservices-demo/tree/master/src/productcatalogservice#latency-injection) into all server requests. We’ll show how to use Stackdriver and Istio together to
view the latency difference between the existing `productcatalog` deployment and the
slower v2 deployment.

## Prerequisites

- [A running Google Kubernetes Engine cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster)
- [A Stackdriver workspace set up for your GCP project](https://cloud.google.com/monitoring/workspaces/)
- [Istio installed on the GKE
  cluster](https://cloud.google.com/istio/docs/istio-on-gke/installing#adding_istio_on_gke_to_an_existing_cluster)
- Istio auto-injection enabled for the default namespace: `kubectl label namespace default istio-injection=enabled`
- [microservices-demo deployed onto the cluster](https://github.com/GoogleCloudPlatform/microservices-demo#option-3-using-static-images)

## Steps

1. Label the existing `productcatalogservice` as `v1`:

```
kubectl label pods --selector=app=productcatalogservice version=v1
```

2. Create an Istio [DestinationRule]((https://istio.io/docs/reference/config/istio.networking.v1alpha3/#DestinationRule)) for `productcatalogservice`

```
kubectl apply -f destinationrule.yaml
```

3. Deploy `productcatalog` v2:
```
kubectl apply -f productcatalog-v2.yaml
```

4. Verify that the `v2` pod is Running:
```
productcatalogservice-v2-79459dfdff-6qdh4   2/2       Running   0          1m
```

5. Create an Istio [VirtualService](https://istio.io/docs/reference/config/istio.networking.v1alpha3/#VirtualService) to split incoming `productcatalog` traffic between v1 (75%) and v2 (25%).
```
kubectl apply -f vs-split-traffic.yaml
```

6. In a web browser, navigate to the hipstershop frontend. You can get the `EXTERNAL_IP` address of
   the frontend by running:
```
kubectl get svc -n istio-system istio-ingressgateway
```

7. Refresh the homepage a few times. You should notice that periodically, the frontend is
   slower to load. Let’s dive into the latency metrics for `productcatalog`.
8. In a browser, open [Stackdriver Monitoring](https://app.google.stackdriver.com). In the left sidebar, navigate to **Resources > Metrics Explorer.**
9. In the left bar, enter the following:
	- **Resource type**: Kubernetes Container
	- **Metric**: Server Response Latencies (`istio.io/service/server/response_latencies`)
	- **Group by**: `destination_workload_name`
	- **Aligner**: 50th percentile
	- **Reducer**: mean
	- **Alignment period**: 1 minute

10. In the menubar of the chart on the right, choose the **Line** type.
11. Once the latency chart renders, you should see `productcatalog-v2` as an outlier, with
    mean latencies hovering at 3 seconds. This is the value of `EXTRA_LATENCY` we injected into v2.

![metrics explorer](screenshots/metrics-explorer.png)

You’ll also notice that other services (such as `frontend`) have a latency spike. This is because the [frontend relies on](https://github.com/GoogleCloudPlatform/microservices-demo#service-architecture) productcatalog, for which 25% of requests are routing through the slower `v2` deployment.

![v2 latency](screenshots/v2-latency.png)

12. Let’s return 100% of all `productcatalog` traffic to `v1`:
```
kubectl apply -f rollback.yaml
```
14. Finally, remove `v2`:
```
kubectl delete -f productcatalog-v2.yaml
```


## Learn More

- [Incremental Istio Part 1, Traffic Management](https://istio.io/blog/2018/incremental-traffic-management/)
- [Canary Deployments using Istio](https://istio.io/blog/2017/0.1-canary/)  (Istio blog)
