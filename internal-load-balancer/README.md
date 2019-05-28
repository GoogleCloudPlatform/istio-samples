# Demo: Using a GCP Internal Load Balancer with Istio  

This demo shows how connect a worload running in a GCE Virtual Machine with Istio-enabled workloads on Google Kubernetes Engine, using an internal endpoint that is only accessible within your Virtual Private Network in GCP.  

**Note**: [ILB for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/internal-load-balancing) is currently beta.

## How It Works 

An Internal Load Balancer (ILB) is a GCP resource that exposes workloads (in GCE or GKE) to within the same region and the same [Virtual Private Cloud](https://cloud.google.com/vpc/) (VPC) network. 

Using an ILB substitutes having to use a GKE external load balancer with a set of firewall rules.  

With Istio, can use the built-in ILB Gateway on install (comparable to the default IngressGateway, but internal) to expose your services to workloads running in GKE and GCE in the same VPC.  

The ILB Gateway itself is an Istio-deployed Envoy proxy that can be [configured with Gateway resources](https://istio.io/docs/tasks/traffic-management/ingress/#configuring-ingress-using-an-istio-gateway) just like the Istio Ingress Gateway. 

In this demo, we'll create the following architecture: 


## Prerequisites 

- A GCP project with billing enabled 
- the Helm CLI on your local machine 

## 1 - Create a GKE Cluster  

Export your project ID: 

```
PROJECT_ID=<your-project-id> 
```

Create the cluster: 

```
gcloud container clusters create istio-ilb3 --project $PROJECT_ID --zone us-east4-a \
--machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
--num-nodes "4" --network "default" --async
```

Wait for it to be running. 

Get credentials, grant rbac 

```
gcloud container clusters get-credentials istio-ilb3 --zone us-east4-a --project $PROJECT_ID

kubectl create clusterrolebinding cluster-admin-binding \
--clusterrole=cluster-admin \
--user=$(gcloud config get-value core/account)
```

## 2 - Install Istio with ILB Gateway Enabled 

Download the Istio 1.1.7 release: https://github.com/istio/istio/releases 

`cd istio-1.**/` 

Prepare the cluster for install: 

```
kubectl create namespace istio-system
kubectl label namespace default istio-injection=enabled 
helm template istio-1.1.7/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
```

Wait for CRDs to be ready:
```
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
```

Should see `53`. 

Generate the Istio installation YAML. Note that we're enabling the option to deploy the ILB Gateway. 
```
helm template ./istio-1.1.7/install/kubernetes/helm/istio --name istio --namespace istio-system \
   --set prometheus.enabled=true \
   --set kiali.enabled=true --set kiali.createDemoSecret=true \
   --set "kiali.dashboard.jaegerURL=http://jaeger-query:16686" \
   --set "kiali.dashboard.grafanaURL=http://grafana:3000" \
   --set grafana.enabled=true \
   --set sidecarInjectorWebhook.enabled=true \
   --set gateways.istio-ilbgateway.enabled=true > istio.yaml
```

*Optional* - Open `istio.yaml` and search the file for `istio-ilbgateway`. You will find a Kubernetes Service, `istio-ilbgateway`, that is Service type=LoadBalancer, but has the annotation: `cloud.google.com/load-balancer-type: "internal"`.  This means that rather than provisioning an external [Network Load Balancer](https://cloud.google.com/load-balancing/docs/network/) for Istio's ILB gateway, GKE will create an [Internal Load Balancer](https://cloud.google.com/load-balancing/docs/internal/) instead.  
[See the GCP docs](https://cloud.google.com/kubernetes-engine/docs/how-to/internal-load-balancing#create) for more information.

Also note that the Istio ILB Gateway has [more customization options](https://istio.io/docs/reference/config/installation-options/#gateways-options) on install that we aren't using here, that would be useful for production use cases-- for example, autoscaling options, Memory and CPU allocations, and custom cert paths.  

Install Istio on the cluster: 
```
kubectl apply -f istio.yaml
```

Run `kubectl get pods -n istio-system`. Notice a pod with the name prefix `istio-ilbgateway`. This is the proxy that will handle our requests from GCE, in just a moment. 

## 3 - Deploy the HelloServer application 

This will deploy 2 pods to Kubernetes: one is 

```
kubectl apply -f ../sample-apps/helloserver/server/server.yaml 

kubectl apply -f ../sample-apps/helloserver/loadgen/loadgen.yaml 
```

## 4 - Open Kiali in a browser 

```
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001
```

Log in as `admin/admin`. 

View the Service graph for the Default namespace: 

![service-graph](images/default-svc-graph.png)

Now imagine that we want to reach HelloService from a workload not in the mesh, and from outside of GKE. 

Right now, HelloServer is not exposed to the Internet -- we have a `ClusterIP` service that allows Istio to track it, and allows the `loadgen` pod to reach it via kubedns (`hellosvc:80`). 

One route to do this is [Mesh Expansion](https://github.com/GoogleCloudPlatform/istio-samples/tree/master/mesh-expansion-gce) which installs Istio on the VM itself, and logically and functionally brings the VM into the service mesh. But if (for administrative, complexity, or other reasons) we want to keep the GCE VM out of the mesh, but also not expose HelloSvc to the public internet, we can use the ILB Gateway to do this.  

## 5 - Create a GCE VM 

First let's create a VM in the same project that will interact with GKE. **Note** how we've created this VM in the same region as the GKE cluster. This (same region) is a prerequisite for GCP resource communication via ILB. Also notice that `--network=default` means we're creating the GCE VM in the same VPC network as the GKE cluster. 

```
gcloud compute --project=$PROJECT_ID instances create gce-ilb2 --zone=us-east4-a --machine-type=n1-standard-2 --network=default
```


## 6- Modify the ILB Gateway's Ports 

Run this command, and examine the output:

```
kubectl get svc -n istio-system istio-ilbgateway -o yaml
``` 

Notice that under the `ports` field, there are four ports defined, all for internal Istio purposes; neither port `80` nor `443` (for HTTP/S) are exposed by default. 

So let's modify the ILB Gateway to additionally accept HTTP traffic on port 80.

**Note** - There is [a limitation of 5 ports](https://cloud.google.com/load-balancing/docs/internal/#forwarding_rule) for a GCP Internal Load Balancer. Outside of Kubernetes, there is an option to enable `all` ports, but you must provide a specific list of ports to expose for a Kubernetes service. 

```
kubectl apply -f istio/ilb-gateway-modified.yaml 
```

## 7 - Expose HelloServer via the ILB Gateway  

If we want to send traffic from GCE to GKE, via the Istio ILB Gateway, we will have to expose HelloServer within GCP. This will be the same process as if we were exposing HelloServer to the public internet ([with the IngressGateway](https://istio.io/docs/tasks/traffic-management/ingress/#configuring-ingress-using-an-istio-gateway)). For this, we'll use an Istio `Gateway` resource, along with a `VirtualService`. 

Open `istio/server-ilb.yaml` to examine its contents. 

Apply: 
```
kubectl apply -f istio/server-ilb.yaml 
```


## 8 - Send Traffic from GCE --> GKE via ILB Gateway 

Remember that the Istio ILBGateway service is `type=LoadBalancer`. This means it gets an `EXTERNAL_IP`, but only "external" within our region VPC network: 

Run: 
```
kubectl get svc -n istio-system istio-ilbgateway
``` 

You should see something like: 

NAME               TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                                      AGE
istio-ilbgateway   LoadBalancer   10.67.240.220   10.150.0.7    15011:32390/TCP,15010:32626/TCP,8060:32429/TCP,5353:32066/TCP,80:32624/TCP   39m
```

Copy the `EXTERNAL_IP` to the clipboard. 

SSH into the GCE VM we created earlier: 

```
gcloud compute ssh --project $PROJECT_ID  --zone "us-east4-a" gce-ilb2 
```

Try to hit helloserver via the ILB gateway IP, at port 80:

```
curl http://10.150.0.7:80 
```

You should see: 

```
Hello World! /
```

Notice that if you try to execute the same `curl` request on your local machine, you will time out -- this because the ILB Gateway is only exposed from within your GCP project's private VPC network. 

🌟 Well done - you just exposed a GKE service via Istio's ILB Gateway! 