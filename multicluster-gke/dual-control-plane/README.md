# Demo: Multicluster Istio - Gateway-Connected Clusters

This example shows how to orchestrate an application with [Istio](https://istio.io/) across two different
Google Kubernetes Engine clusters. To do this, we will unite two different Istio service meshes into
one logical, hybrid mesh.

![dual-screenshot](screenshots/topology.png)

This example is relevant if you run microservices on two different cloud platforms, or are
using a combination of on-prem and cloud Kubernetes. For demonstration purposes here, we'll use two GKE clusters in two different projects, and thus two
different [virtual networks](https://cloud.google.com/kubernetes-engine/docs/concepts/network-overview#inside-cluster).

## How it works

This demo uses Istio 1.1's [Gateway-Connected Clusters](https://preliminary.istio.io/docs/concepts/multicluster-deployments/#multiple-control-plane-topology) feature. This is a specific mode of
multicluster Istio where two separate Kubernetes clusters run their own Istio control
plane, and orchestrate their own mesh. But each Istio control plane also runs a CoreDNS
server, which allows services in both clusters to refer to services in the other cluster,
as if they were part of their own mesh. A service in cluster 1 can call a
cluster 2 service with a DNS name of the format `svc-name.cluster-2-namespace.global`.
The Kubernetes DNS server and Istio's CoreDNS know how to work together to resolve that
`global` DNS suffix.


## Prerequisites

- Two GCP projects with billing and the Kubernetes API enabled
- `gcloud` CLI
- `kubectl`
- `helm` CLI


## Set Env Variables

```
export PROJECT_1=<your-project1>

export PROJECT_2=<your-second-project>
```

## 1 - Create Two GKE Clusters

```
./scripts/1-create-gke-clusters.sh
```

Then, run:

```
watch -n 1 gcloud container clusters list
```

And wait for both clusters to be `RUNNING`.


## 2- Prepare both GKE Clusters

This script installs Helm onto each cluster, along with the Istio Custom Resource
Definitions (CRDs).

```
./scripts/2-istio-preinstall.sh
```

Once the script finishes, verify (in both projects) that there are `23` Istio CRDs ready (or `53`, if using Istio 1.1):

```
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
```

## 3 - Install Istio on Both Clusters

```
./scripts/3-istio-install.sh
```

Wait for all Istio pods to be `RUNNING` and `READY`:

```
NAME                                     READY   STATUS      RESTARTS   AGE
istio-citadel-5f5f589d85-ngwzx           1/1     Running     0          2m10s
istio-egressgateway-586b67d9f9-rvgdl     1/1     Running     0          2m10s
istio-galley-69dddcdb6d-ftc9k            1/1     Running     0          2m10s
istio-ingressgateway-6cb57df9d5-s82ml    1/1     Running     0          2m10s
istio-init-crd-10-44ftr                  0/1     Completed   0          3m41s
istio-init-crd-11-bbf6m                  0/1     Completed   0          3m41s
istio-init-crd-12-gd2fc                  0/1     Completed   0          3m41s
istio-pilot-55b94698c4-5s8l4             2/2     Running     0          2m10s
istio-policy-68b4bf556d-9l7sj            2/2     Running     2          2m10s
istio-sidecar-injector-68bf9645b-2qfrv   1/1     Running     0          2m10s
istio-telemetry-659fc8767d-4qt9h         2/2     Running     2          2m10s
istiocoredns-586757d55d-bjzz9            2/2     Running     0          2m10s
prometheus-5b48f5d49-pdsts               1/1     Running     0          2m10s
```

## 4 - Configure KubeDNS to talk to Istio's CoreDNS

You'll notice `istiocoredns` in the pods list. This DNS server which will handle DNS resolution across
cluster boundaries.

The next step configures the Kubernetes server (kubedns) to with a
DNS
[stub domain](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/#configure-stub-domain-and-upstream-dns-servers)
to talk to this auxiliary Istio CoreDNS server.
A StubDomain is a forwarding rule for DNS addresses with a certain prefix.

Run the script to configure the stub domain on both GKE clusters:

```
./scripts/4-configure-dns.sh
```


## 5- Deploy the Sample App

We will now deploy [Hipstershop, a sample application](https://github.com/GoogleCloudPlatform/microservices-demo), across our two GKE clusters.

For demonstration purposes, we've split the microservices into two halves. One group
will run on Cluster 1 (namespace `hipster1`):

- emailservice
- checkoutservice
- paymentservice
- currencyservice
- shippingservice
- adservice

And another group will run on Cluster 2 (namespace
`hipster2`):

- frontend
- productcatalogservice
- recommendationservice
- cartservice (configured to use a local store, not Redis)


Visually, we will deploy this topology:

![dual-screenshot](screenshots/topology.png)

The following script creates the following resources on both GKE clusters:
- Kubernetes Deployments for the services assigned to this cluster
- Kubernetes Services for the services that *are* running local to this cluster
- ServiceEntries (type `MESH_INTERNAL`) for all the services *not* running on this cluster. **Note**: for each
  of these external ServiceEntries, the script injects the Istio `IngressGateway` IP for the
  opposite cluster. This is how CoreDNS will be able to resolve `global` to an actual
  external Istio IP.
- ServiceEntries (type `MESH_EXTERNAL`) to access external Google APIs (necessary for
  Hipstershop to run)
- Istio VirtualServices / Gateway (for cluster 2 / the frontend only)

Run the script to deploy these resources across both clusters:

```
./scripts/5-deploy-hipstershop.sh
```


## Verify success

Open Hipstershop in a browser.


If it works, you just deployed Multicluster Istio across
two separate networks, then ran an application that spanned two Kubernetes
environments! All part of a single, two-headed Service Mesh. 🎉


## Troubleshooting


If you open Hipstershop in a browser, see a `500` error like this:

![500-error](screenshots/500-error.png)

This means the Frontend (in cluster 2) cannot access services running on cluster 1.

To debug, make sure that the Frontend's Envoy sidecar can ping a cluster-1 service:

```
$ kubectl exec -it frontend-85d9fd86f8-8gkpq -c istio-proxy -n hipster2 /bin/sh

$ ping currencyservice.hipster1.global
PING currencyservice.hipster1.global (127.255.0.4) 56(84) bytes of data.
64 bytes from 127.255.0.4: icmp_seq=1 ttl=64 time=0.030 ms
```


## Clean up

Delete the 2 GKE clusters:

```
./scripts/cleanup-delete-clusters.sh
```

## Further reading

To learn about Multicluster Istio and its different modes, [see the Istio docs](https://preliminary.istio.io/docs/concepts/multicluster-deployments/).
