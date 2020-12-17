FROM python:3.9-slim as base
FROM base as builder
RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        g++ \
    && rm -rf /var/lib/apt/lists/*

# Enable unbuffered logging
FROM base as final
ENV PYTHONUNBUFFERED=1

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        wget

WORKDIR /helloserver

# Grab packages from builder
COPY --from=builder /usr/local/lib/python3.9/ /usr/local/lib/python3.9/

# Add the application
COPY . .

EXPOSE 8080
ENTRYPOINT [ "python", "server.py" ]
