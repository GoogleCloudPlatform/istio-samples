## Sample App: helloserver 

The `helloserver` application is a small sample application designed to be used for "hello world" Istio demos. 

The application consists of two services:
1) `helloserver`, a tiny HTTP server written in Python. The `GET /` endpoint returns `hello world` 
2) `loadgen`, a Python script that can generate a configurable number of requests to `helloserver`. The loadgen is designed to generate observability metrics for Istio and Kiali.   

For a more complex microservices example, see the [Hipstershop Demo](https://github.com/GoogleCloudPlatform/microservices-demo).