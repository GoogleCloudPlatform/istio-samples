# Copyright 2019 Google LLC
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

FROM gcr.io/gcp-runtimes/go1-builder:1.12 as build

ENV GOPATH /go
ENV GOROOT /usr/local/go
ENV PATH ${GOROOT}/bin:${PATH}

WORKDIR /src

RUN echo 'nobody:x:65534:' > /src/group.nobody && \
    echo 'nobody:x:65534:65534::/:' > /src/passwd.nobody

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git

COPY go.mod go.sum /src/

RUN go mod download

COPY client.go /src/

RUN GO111MODULE=on CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install -installsuffix "static" client.go

FROM gcr.io/distroless/static

COPY --from=build /src/group.nobody /etc/group
COPY --from=build /src/passwd.nobody /etc/passwd
USER nobody:nobody

COPY --from=build /go/bin/client /bin/greeter-client

ENTRYPOINT ["/bin/greeter-client"]
