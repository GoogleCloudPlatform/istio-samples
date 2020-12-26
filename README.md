# ⛵️ istio-samples

This repository contains Google Cloud Platform demos and sample code for [Istio](https://istio.io/).

**⚠️ Note**: These samples are last updated to the [Istio 1.5 release](https://github.com/istio/istio/releases/), and are no longer under active development. See the [Istio documentation](https://istio.io/) for the most up-to-date examples.

## Contents

### [Canary Deployments with Istio on GKE](/istio-canary-gke)

Uses the [Hipstershop](https://github.com/GoogleCloudPlatform/microservices-demo) sample app to demonstrate traffic splitting with Istio on GKE, and how to view Istio-generated metrics in Stackdriver.

### [Introduction to Istio Security](/security-intro)

Provides an introduction to Istio service-to-service encryption (mutual TLS), end-user authentication (JSON Web Tokens), and service authorization (role-based access control).

### [Istio and Stackdriver](/istio-stackdriver)

A deep-dive on how to use Stackdriver to monitor Istio services' health, analyze traces, and view logs.

### [Using a GCP Internal Load Balancer with Istio](/internal-load-balancer)

Demonstrates how to connect GCE (VM-based) workloads to Istio services running in GKE, through a private internal load balancer on GCP.

### [Geo-Aware Istio Multicluster Ingress](/multicluster-ingress)

Shows how to attach a global Anycast IP address to multiple Istio IngressGateways running in clusters across regions.

### [Integrating a Google Compute Engine VM with Istio](/mesh-expansion-gce)

Demonstrates how to do Istio Mesh Expansion: the process of incorporating a GCE-based workload into an Istio mesh running in GKE.

### [Multicluster Istio- Single Control Plane](/multicluster-gke/single-control-plane)

Introduces Multicluster Istio by uniting GKE workloads in two different clusters into a single Istio mesh.

### [Multicluster Istio- Dual Control Plane](/multicluster-gke/dual-control-plane)

Shows how to connect two separate GKE clusters, each with their own Istio control planes, into a single Gateway-connected mesh.

### [Virtual Machine Migration with Multicluster Istio](/multicluster-gke/vm-migration/)

Demonstrates how to integrate an Istio-enabled VM into a multicluster mesh, then migrate traffic from the VM to GKE.