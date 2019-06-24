# grpc-greeter-go

This sample application consists of a gRPC server and client.

It is a adapted from
[the gRPC-Go helloworld example](https://github.com/grpc/grpc-go/tree/master/examples/helloworld).

The main changes from the original version are:

- the server returns the hostname where it runs in a gRPC header; and

- the client prints the hostname header from the gRPC response.

This is useful for testing request routing and load balancing functionality.

When running in a Kubernetes cluster, the hostname is the name of the
Kubernetes Pod that served the request.

## Usage

Build container images for the gRPC client and server:

    docker build client -t grpc-greeter-go-client
    
    docker build server -t grpc-greeter-go-server

Start the server:

    docker run --detach --name grpc-server --rm grpc-greeter-go-server --address :8000

Run the client and send three requests:

    docker run --network container:grpc-server --rm grpc-greeter-go-client --address localhost:8000 --insecure --repeat 3

Stop the server:

    docker stop grpc-server

## Disclaimer

This is not an officially supported Google product.
