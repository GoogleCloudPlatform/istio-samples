# Multicluster Istio with Virtual Machines

Istio can help you modernize your existing infrastructure. Istio works with services running in Kubernetes containers, but it also works with virtual machines.

Let's say we want to deploy a multi-service application. This application consists mostly of Kubernetes-ready microservices (running across two cloud datacenters in `us-west` and `us-east`), but one of the older services (`productcatalog`) runs in a virtual machine - in this case, in `us-central`. We can still get all the benefits of Istio (telemetry, security, traffic policies) for that virtual machine service, even with this geographically distributed architecture. And then when we're ready to move `productcatalog` from a VM to a container running in Kubernetes, Istio can help us to that migration with zero downtime. Let's see how that works.

In this sample, we will:
1. install dual control plane Istio multicluster across two GKE clusters
2. create a Google Compute Engine virtual machine in the same project, and add it to the mesh
3. deploy the onlineboutique sample app distributed across both clusters and the VMs
4. use Istio traffic splitting to slowly migrate the VM service to GKE

![](screenshots/arch.png)

*Note* - Why do multicluster Istio (dual control plane) with VMs? Why invest in this complexity? It's a good practice to run an Istio control plane per region - this way, if one region has an outage, services in another region would still be reachable. This is why we're deploying two Istio control planes.


### Setup

1. Set your project ID.
```
export PROJECT_ID="<your-project-id>"
```

2. Run the first script to create two GKE clusters and one GCE instance in your project.

```
./scripts/1-create-infra.sh
```

3. Wait for the clusters to be `RUNNING`.

```
watch gcloud container clusters list

NAME      LOCATION    MASTER_VERSION  MASTER_IP      MACHINE_TYPE
NODE_VERSION    NUM_NODES  STATUS
cluster2  us-east1-b  1.14.10-gke.27  35.196.192.71  n1-standard-2
1.14.10-gke.27  4          RUNNING
cluster1  us-west1-b  1.14.10-gke.27  34.83.227.203  n1-standard-2
1.14.10-gke.27  4          RUNNING
```


4. Create firewall rules to allow traffic from the GKE pods in both clusters to your GCE instance. This is what allows Istio sidecar proxies to talk to each other across the different infrastructure - and what will connect the VM service with the others running in GKE.

```
./scripts/2-firewall.sh
```


5. Install the Istio control plane on both GKE clusters. Connect the two Istio control planes into one logical mesh by updating the KubeDNS stubdomain - this is what will allow cross-cluster GKE mesh traffic to resolve to local Kubernetes services on the opposite cluster. See the Istio docs for more information on how this works.

```
./scripts/3-install-istio-gke.sh
```


6. Gather and send information about both Kubernetes clusters to the GCE VM. This script also `ssh`-es into the VM, installs Istio, Docker, and deploys `productcatalogservice` onto the VM, via Docker.


### Deploy the sample application

Deploy the sample app across both GKE clusters (minus `productcatalogservice`). We'll use ServiceEntries to resolve DNS across for services on the opposite cluster. See the Istio docs for more information.

Deploy productcatalogservice on the VM.

Add productcatalogservice to the mesh.


Open the frontend in a web browser via the Istio Ingressgateway on cluster2.


Open the service graph for cluster2.

### Migrate the VM service to GKE

