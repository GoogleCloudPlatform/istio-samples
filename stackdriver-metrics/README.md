# Configuring Stackdriver Monitoring for Open Source Istio

- [Background](#background)
- [Stackdriver Adapter](#stackdriver-adapter)
- [Stackdriver Metrics](#stackdriver-metrics)
- [Usage](#usage)
- [Customizations](#customizations)

## Background

Per the [Istio](https://istio.io) concept documentation on [Observability](https://istio.io/docs/concepts/observability/):

> Istio generates detailed telemetry for all service communications within a mesh. This telemetry provides observability of service behavior, empowering operators to troubleshoot, maintain, and optimize their applications – without imposing any additional burdens on service developers. Through Istio, operators gain a thorough understanding of how monitored services are interacting, both with other services and with the Istio components themselves.

[Mixer](https://istio.io/docs/reference/config/policy-and-telemetry/mixer-overview/) is the Istio component responsible for providing telemetry collection, as well as policy controls. Mixer supports [Adapters](https://istio.io/docs/reference/config/policy-and-telemetry/mixer-overview/#adapters), so that it can plug-in to different infrastructure backends for logging, metrics, and tracing support:

> Mixer is a highly modular and extensible component. One of its key functions is to abstract away the details of different policy and telemetry backend systems, allowing the rest of Istio to be agnostic of those backends.
>
> Mixer’s flexibility in dealing with different infrastructure backends comes from its general-purpose plug-in model. Individual plug-ins are known as adapters and they allow Mixer to interface to different infrastructure backends that deliver core functionality, such as logging, monitoring, quotas, ACL checking, and more. The exact set of adapters used at runtime is determined through configuration and can easily be extended to target new or custom infrastructure backends.

## Stackdriver Adapter

If you are using [Istio on GKE](https://cloud.google.com/istio/docs/istio-on-gke/overview) then the [Stackdriver](https://cloud.google.com/istio/docs/istio-on-gke/overview#stackdriver_support) adapter is automatically installed for you.

If you've installed Istio via the [Quick Start Evaluation Install](https://istio.io/docs/setup/kubernetes/install/kubernetes/) or [Customizable Install with Helm](https://istio.io/docs/setup/kubernetes/install/helm/) then you will need to configure the Stackdriver adapter.

## Stackdriver Metrics

The [istio-stackdriver-metrics](istio-stackdriver-metrics.yaml) manifest contains Istio [Handler](https://istio.io/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Handler), [Rule](https://istio.io/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Rule), and [Instance](https://istio.io/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Instance) objects configured for capturing telemetry data and sending it to Stackdriver.

## Usage

### Step 1: Install Istio on a GKE cluster

Follow the steps outlined in [Install Istio on a GKE cluster](https://cloud.google.com/istio/docs/how-to/installing-oss) to get a cluster up and running.

### Step 2: Configure Stackdriver adapter

`kubectl apply -n istio-system -f istio-stackdriver-metrics.yaml`

### Step 3: Enable automatic sidecar injection

`kubectl label ns default istio-injection=enabled`

### Step 4: Deploy a sample application

[Hipster Shop](https://github.com/GoogleCloudPlatform/microservices-demo/) is a sample cloud-native microservices application with 10 services and a built-in load generator. 

First, deploy the Hipster Shop Istio manifests:
- `kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml`

Next, deploy the Hipster Shop Kubernetes manifests:
- `kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml`

### Step 5: View metrics in Stackdriver

After a few minutes, the `loadgenerator` built-in to Hipster Shop will have generated some meaningful metrics. At that point, navigate to the [Stackdriver Monitoring](https://app.google.stackdriver.com/) [Metrics Explorer](https://app.google.stackdriver.com/metrics-explorer) and start selecting Istio metrics to display. 

For further exploration, refer to [Istio and Stackdriver Monitoring](https://github.com/GoogleCloudPlatform/istio-samples/tree/master/istio-stackdriver#monitoring) to create example dashboards.

### Step 6: Cleanup

`gcloud container clusters delete [CLUSTER-NAME]`

## Customizations

If you need to make any customizations to [istio-stackdriver-metrics](istio-stackdriver-metrics.yaml), you can generate your own manifest as described in the [README](https://github.com/istio/istio/tree/master/mixer/adapter/stackdriver) for the Istio Stackdriver adapter.