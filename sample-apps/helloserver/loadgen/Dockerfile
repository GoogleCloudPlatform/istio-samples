
FROM python:3-slim as builder  

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        g++ \
    && rm -rf /var/lib/apt/lists/*

# get packages
COPY requirements.txt .
RUN pip install -r requirements.txt

FROM builder as final  

# Enable unbuffered logging
ENV PYTHONUNBUFFERED=1

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        wget

WORKDIR /loadgen

# Grab packages from builder
COPY --from=builder /usr/local/lib/python3.7/ /usr/local/lib/python3.7/

# Add the application
COPY . .

EXPOSE 8080
ENTRYPOINT [ "python", "loadgen.py" ]
