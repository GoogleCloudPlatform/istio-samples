# Demo: Introduction to Istio Security

This example demonstrates how to leverage [Istio's](https://istio.io/docs/concepts/security/) **identity** and **access control** policies to help secure microservices running on [GKE](https://cloud.google.com/kubernetes-engine/).

We'll use the [Hipstershop](https://github.com/GoogleCloudPlatform/microservices-demo) sample application to cover:

*   Incrementally adopting Istio **mutual TLS** authentication across the service mesh
*   Enabling **end-user (JWT)** authentication for the frontend service
*   Using an Istio **access control policy** to secure access to the frontend service

### Contents

  - [Setup](#setup)
    - [Create a GKE Cluster](#create-a-gke-cluster)
    - [Deploy the Sample Application](#deploy-the-sample-application)
  - [Authentication](#authentication)
    - [Enable mTLS for the frontend service](#enable-mtls-for-the-frontend-service)
    - [Enable mTLS for the default namespace](#enable-mtls-for-the-default-namespace)
    - [Add End-User JWT Authentication](#add-end-user-jwt-authentication)
  - [Authorization](#authorization)
    - [Enable authorization (RBAC) for the frontend](#enable-authorization-(rbac)-for-the-frontend)
    - [Control access to the frontend](#control-access-to-the-frontend)
  - [Cleanup](#cleanup)
  - [What's next?](#whats-next)

## Setup

[Google Cloud Shell](https://cloud.google.com/shell/docs/) is a browser-based terminal that Google provides to interact with your GCP resources. It is backed by a free Compute Engine instance that comes with many useful tools already installed, including everything required to run this demo.

Click the button below to open the demo instructions in your Cloud Shell:

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/open?git_repo=https%3A%2F%2Fgithub.com%2FGoogleCloudPlatform%2Fistio-samples&page=editor&tutorial=security-intro/README.md)

1. Change into the demo directory.

```
cd security-intro
```

### Create a GKE Cluster

1. From Cloud Shell, **enable the Kubernetes Engine API**.

```
gcloud services enable container.googleapis.com
```

2. **Create a GKE cluster**.

```
gcloud beta container clusters create istio-security-demo \
    --zone=us-central1-f \
    --machine-type=n1-standard-2 \
    --num-nodes=4
```

3. **Install Istio** on the cluster using Helm.

```
chmod +x ../common/install_istio.sh; ../common/install_istio.sh
```

4. Wait for all Istio pods to be `Running` or `Completed`.
```
kubectl get pods -n istio-system
```

### Deploy the sample application

1. **Deploy the sample application.**

```
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml
```


2. Run `kubectl get pods -n default` to ensure that all pods are `Running` and `Ready`.

```
NAME                                     READY     STATUS    RESTARTS   AGE
adservice-76b5c7bd6b-zsqb8               2/2       Running   0          1m
checkoutservice-86f5c7679c-8ghs8         2/2       Running   0          1m
currencyservice-5749fd7c6d-lv6hj         2/2       Running   0          1m
emailservice-6674bf75c5-qtnd8            2/2       Running   0          1m
frontend-56fdfb866c-tvdm6                2/2       Running   0          1m
loadgenerator-b64fcb8bc-m6nd2            2/2       Running   0          1m
paymentservice-67c6696c54-tgnc5          2/2       Running   0          1m
productcatalogservice-76c6454c57-9zj2v   2/2       Running   0          1m
recommendationservice-78c7676bfb-xqtp6   2/2       Running   0          1m
shippingservice-7bc4bc75bb-kzfrb         2/2       Running   0          1m
```

🔎 Each pod has 2 containers, because each pod now has the injected Istio
sidecar proxy. (the cartservice and redis pods live in the `cart` namespace,
but will not be used for the purposes of this demo.)

Now we're ready to enforce security policies for this application.

## Authentication

[**Authentication**](https://istio.io/docs/concepts/security/#authentication) refers to identity: who is this service? who is this end-user? and can I trust that they are who they say they are?

One benefit of using Istio that it provides **uniformity** for both service-to-service and end
user-to-service authentication. Istio **abstracts** away authentication from
your application code, by [tunneling](https://istio.io/docs/concepts/security/#mutual-tls-authentication) all service-to-service communication through the Envoy
sidecar proxies. And by using a **centralized** [Public-Key
Infrastructure](https://istio.io/docs/concepts/security/#pki), Istio provides **consistency** to make sure authentication is set up
properly across your mesh. Further, Istio allows you to adopt mTLS on a per-service basis,
or **easily toggle end-to-end encryption** for your entire
mesh. Let's see how.


### Enable mTLS for the frontend service

Right now, the cluster is in `PERMISSIVE` mTLS mode, meaning all service-to-service ("east
west") mesh traffic is unencrypted by default. First, let's toggle mTLS for the [frontend](https://github.com/GoogleCloudPlatform/microservices-demo/tree/master/src/frontend)
microservice.

For both inbound and outbound requests for the frontend to be encrypted, [we need two
Istio resources](https://istio.io/docs/concepts/security/#authentication-policies): a
`Policy` (require TLS for inbound requests) and a `DestinationRule` (TLS for the
frontend's outbound requests).

1. **View** both these resources in `./manifests/mtls-frontend.yaml`.

2. **Apply** the resources to the cluster:

```
kubectl apply -f ./manifests/mtls-frontend.yaml
```

3. **Verify that mTLS is enabled** for the frontend by trying to reach it from the
`istio-proxy` container of a different mesh service.

First, try to reach `frontend` from `productcatalogservice` with plain HTTP.

```
kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl http://frontend:80/ -o /dev/null -s -w '%{http_code}\n'
```

You should see:

```
000
command terminated with exit code 56
```

Exit code `56` [means](https://curl.haxx.se/libcurl/c/libcurl-errors.html) "failure to
receive network data." This is expected.

4. Now run the same command but **with HTTPS**, passing the client-side
key and cert for `productcatalogservice`.

```
kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl https://frontend:80/ -o /dev/null -s -w '%{http_code}\n'  --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
```

✅ You should now see a `200 - OK` response code.

🔎 The TLS key and certificate for `productcatalogservice` comes from Istio's
Citadel component, running centrally. [Citadel generates](https://istio.io/docs/concepts/security/#kubernetes-scenario) keys and certs for all mesh
services, even if the cluster-wide mTLS is set to `PERMISSIVE`.

### Enable mTLS for the default namespace

Now that we've adopted mTLS for one service, let's enforce mTLS for the [entire
`default`
namespace](https://istio.io/docs/tasks/security/authn-policy/#namespace-wide-policy).
Doing so will automatically encrypt service-to-service traffic for every Hipstershop service
running in the `default` namespace.

1. **Open** `manifests/mtls-default-ns.yaml`. Notice that we're using the same resources
(`Policy` and `DestinationRule`) for
namespace-wide mTLS as we did for service-specific mTLS.

2. **Apply** the resources:

```
kubectl apply -f ./manifests/mtls-default-ns.yaml
```

From here, we could enable mTLS globally by applying a
[MeshPolicy](https://istio.io/docs/tasks/security/authn-policy/#globally-enabling-istio-mutual-tls)
resource to the cluster.

### Add End-User JWT Authentication

Now that we've enabled service-to-service authentication in the default namespace, let's
enforce **end-user ("origin") authentication** for the `frontend` service, using [JSON Web Tokens](https://jwt.io/)
(JWT).

⚠️ We recommend only using JWT authentication alongside mTLS (and not JWT by itself), because plaintext JWTs are not
themselves encrypted, only [signed](https://jwt.io/introduction/). Forged or intercepted
JWTs could compromise your
service mesh. In this section, we're building on the mutual TLS authentication already configured for the
default namespace.

First, we'll create an Istio `Policy` to enforce JWT authentication for inbound requests
to the `frontend` service.

1. **Open** the resource in  `./manifests/jwt-frontend.yaml`.

🔎 This `Policy` uses Istio's
test JSON Web Key Set (`jwksUri`), the public key used to verify incoming JWTs.
When we apply this `Policy`, Istio's Pilot component will [pass down](https://istio.io/docs/concepts/security/#authentication-architecture) this public key to
the frontend's sidecar proxy, which will allow it to accept or deny requests.

Also note that this resource updates the existing `frontend-authn` `Policy` we created in
the last section; this is because Istio [only allows one](https://istio.io/docs/concepts/security/#target-selectors) service-matching Policy to exist
at a time.

2. **Apply** the updated frontend Policy:

```
kubectl apply -f ./manifests/jwt-frontend.yaml
```

3. **Set a local `TOKEN` variable.** We'll use this TOKEN on the client-side
   to make requests to the frontend.

```
TOKEN=$(curl -k https://raw.githubusercontent.com/istio/istio/release-1.4/security/tools/jwt/samples/demo.jwt -s); echo $TOKEN
```

4. First try to reach the frontend with TLS keys/certs but **without** a JWT.

```
kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl  https://frontend:80/ -o /dev/null -s -w '%{http_code}\n' \
--key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
```

You should see a `401 - Unauthorized`  response code.

5. Now try to reach the frontend service, with TLS key/certs **and** a JWT:

```
kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl --header "Authorization: Bearer $TOKEN" https://frontend:80/ -o /dev/null -s -w '%{http_code}\n' \
--key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
```

✅ You should see a `200` response code.

🎉 Well done! You just secured the `frontend` service with both transport and origin authentication.


## Authorization

Unlike authentication, which refers to the "who," **authorization** refers to the "what", or: what is this service or user allowed to do?

By default, requests between Istio services (and between end-users and services) are [allowed by default](https://istio.io/docs/concepts/security/#implicit-enablement). You can then enforce authorization for one or many services using an [`AuthorizationPolicy`](https://istio.io/docs/reference/config/security/authorization-policy/) custom resource.

Let's put this into action, by only allowing requests to the `frontend` that have a specific HTTP header.

### Enable authorization (RBAC) for the frontend

1. **Apply the AuthorizationPolicy** for the frontend service:

```
kubectl apply -f ./manifests/authz-frontend.yaml
```

2. Run the same `GET` request to the frontend as we did in the last section  (with TLS
   key/cert and JWT).

```
kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl  --header "Authorization: Bearer $TOKEN" https://frontend:80/ -o /dev/null -s -w '%{http_code}\n' \
--key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
```

You should receive a `403- Forbidden` error. This is expected, because we just locked down the
frontend service to only whitelisted subjects.


3. Make another request from `productcatalogservice` to the `frontend`. This time, **pass
   the `hello:world` request header.**

```
kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl --header "Authorization: Bearer $TOKEN" --header "hello:world"  \
   https://frontend:80/ -o /dev/null -s -w '%{http_code}\n' \
  --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
```

✅ You should now see a `200` response code.

🔎 From here, if you wanted to expand authorization to the entire default namespace, you
can apply similar resources.

🎉 Nice job! You just configured a fine-grained Istio access control policy for one
service. We hope this section demonstrated how Istio can support specific, service-level
authorization policies using a set of familiar, Kubernetes-based RBAC resources.

## Cleanup

To avoid incurring additional costs, delete the GKE cluster created in this demo:

```
gcloud container clusters delete istio-security-demo --zone=us-central1-f
```

Or, to keep your GKE cluster with Istio and Hipstershop still installed, delete the Istio security
resources only:

```
kubectl delete -f ./manifests
```

## What's next?

If you're interested in learning more about Istio's security features, read more at:

*   [Concepts: Istio Security](https://istio.io/docs/concepts/security/)
*   [Task: Authentication Policy / Precedence](https://istio.io/docs/tasks/security/authn-policy/#policy-precedence)
*   [Task: Mutual TLS Migration](https://istio.io/docs/tasks/security/mtls-migration/)
*   [Task: Securing Gateways with HTTPS](https://istio.io/docs/tasks/traffic-management/secure-ingress/)
*   [Task: Mutual TLS Over HTTPS](https://istio.io/docs/tasks/security/https-overlay/)
*   [Example: TLS Origination for Egress Traffic ](https://istio.io/docs/examples/advanced-egress/egress-tls-origination/)
