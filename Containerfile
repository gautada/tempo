# ------------------------------------------------------------- [STAGE] BUILD
ARG DEBIAN_VERSION=latest
FROM gautada/debian:$DEBIAN_VERSION as build

# Install build dependencies
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
    build-essential \
    git \
    golang \
    ca-certificates \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG TEMPO_VERSION=v2.4.1
WORKDIR /src
RUN git clone --branch $TEMPO_VERSION --depth 1 https://github.com/grafana/tempo.git .

# Build Tempo
RUN go mod download
RUN go build -o /usr/bin/tempo ./cmd/tempo

# ------------------------------------------------------------- [STAGE] FINAL
FROM gautada/debian:$DEBIAN_VERSION

# Metadata
LABEL org.opencontainers.image.title="tempo"
LABEL org.opencontainers.image.description="A Grafana Tempo container built from source."
LABEL org.opencontainers.image.source="https://github.com/gautada/tempo"

# Application binaries
COPY --from=build /usr/bin/tempo /usr/bin/tempo

# Configuration directory
RUN mkdir -p /etc/tempo /var/tempo

# Default user setup (tempo)
ARG USER=tempo
RUN /usr/sbin/groupmod -n $USER debian \
 && /usr/sbin/usermod -l $USER -d /home/$USER -m debian \
 && /bin/chown -R $USER:$USER /home/$USER \
 && /bin/chown -R $USER:$USER /var/tempo

# Ports (standard OTLP/Tempo ports)
# 3200: HTTP/Metrics, 9095: gRPC
EXPOSE 3200 9095

USER $USER
WORKDIR /home/$USER

# Entrypoint setup
# Typically requires -config.file=/etc/tempo/tempo.yaml
ENTRYPOINT ["/usr/bin/tempo"]
CMD ["-config.file=/etc/tempo/tempo.yaml"]
