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

## 3 - Deploy the HelloServer application 


## 4- Modify the ILB Gateway's Ports 


## 5 - Create a GCE VM 


## 6 - GCE --> GKE via ILB Gateway 


## 7 - Use Kiali to visualize ILB interactions 

```
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001
```

Log in as `admin/admin`. 