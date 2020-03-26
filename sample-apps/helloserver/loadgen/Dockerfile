FROM gcr.io/google-samples/istio-samples/helloserver/loadgen-base as final

# Enable unbuffered logging
ENV PYTHONUNBUFFERED=1

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        wget

WORKDIR /loadgen

# Add the application
COPY . .

EXPOSE 8080
ENTRYPOINT [ "python", "loadgen.py" ]