
FROM gcr.io/mokeefe/csmready/loadgen-base:v0.0.1 as final

FROM final as builder 

# Enable unbuffered logging
ENV PYTHONUNBUFFERED=1

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        wget

WORKDIR /loadgen

# Grab packages from builder
COPY --from=final /usr/local/lib/python3.7/ /usr/local/lib/python3.7/

# Add the application
COPY . .

EXPOSE 8080
ENTRYPOINT [ "python", "loadgen.py" ]
