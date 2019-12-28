# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# https://docs.docker.com/engine/reference/builder/

FROM gcr.io/cloud-builders/go as build

ENV GOPATH /go
ENV GO111MODULE on

WORKDIR ${GOPATH}/src

RUN wget -O /bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/v0.3.1/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe

COPY go.mod go.sum ./

RUN go mod download

COPY server.go ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install -installsuffix "static" .

# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds

FROM gcr.io/distroless/static:nonroot

COPY --from=build /bin/grpc_health_probe /bin/grpc_health_probe
COPY --from=build /go/bin/server /bin/greeter-server

ENTRYPOINT ["/bin/greeter-server"]
