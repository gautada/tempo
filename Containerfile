# ------------------------------------------------------------- [STAGE] BUILD
ARG DEBIAN_VERSION=latest
FROM docker.io/library/golang:1.25-trixie AS builder

# Install build dependencies
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
    build-essential \
    git \
    ca-certificates 
ARG TEMPO_VERSION=v2.10.3
WORKDIR /build
RUN git config --global advice.detachedHead false \
 && git clone --branch $TEMPO_VERSION --depth 1 \
        https://github.com/grafana/tempo.git . \
 && go mod download \
 && go build -o /out/tempo ./cmd/tempo


FROM gautada/debian:$DEBIAN_VERSION as container

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="temp"
LABEL org.opencontainers.image.description="A Grafana Tempo database."
LABEL org.opencontainers.image.source="https://github.com/gautada/tempo"
LABEL org.opencontainers.image.license="Apache-2.0"


# Standard Loki ports: 3100 (HTTP), 9095 (gRPC)
EXPOSE 3100 9095

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libcap2-bin \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/tempo /usr/bin/tempo

# ╭──────────────────────────────────────────────────────────╮
# │ User                                                     │
# ╰──────────────────────────────────────────────────────────╯
ARG USER=tempo
RUN /usr/sbin/usermod -l $USER debian \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER debian \
 && /bin/passwd -d $USER \
 && rm -rf /home/debian 


# # Ports (standard OTLP/Tempo ports)
# # 3200: HTTP/Metrics, 9095: gRPC
EXPOSE 3200 9095
#
# USER $USER
WORKDIR /home/$USER
#
# # Entrypoint setup
# # Typically requires -config.file=/etc/tempo/tempo.yaml
# ENTRYPOINT ["/usr/bin/tempo"]
# CMD ["-config.file=/etc/tempo/tempo.yaml"]
