# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=docker.io/gautada/debian:latest
ARG TEMPO_VERSION=2.10.3
ARG TARGETARCH=amd64

# ══════════════════════════════════════════════════════════════
# Stage 1: Build Tempo from source
# ══════════════════════════════════════════════════════════════
FROM docker.io/library/golang:1.25-trixie AS builder

ARG TEMPO_VERSION
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
ENV GOOS=linux
ENV GOARCH=${TARGETARCH}

# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    git \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git config --global advice.detachedHead false \
 && git clone --depth 1 --branch "v${TEMPO_VERSION}" https://github.com/grafana/tempo.git .

RUN go build -ldflags "-s -w" -o /build/tempo ./cmd/tempo

# ══════════════════════════════════════════════════════════════
# Stage 2: Final Image
# ══════════════════════════════════════════════════════════════
FROM ${BASE_IMAGE} AS container

ARG TARGETARCH

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="tempo"
LABEL org.opencontainers.image.description="A Grafana Tempo high-scale distributed tracing backend container."
LABEL org.opencontainers.image.source="https://github.com/gautada/tempo"
LABEL org.opencontainers.image.license="Apache-2.0"

ENV DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libcap2-bin \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Application layout
RUN mkdir -p /etc/tempo \
           /var/tempo

# Tempo binary
COPY --from=builder /build/tempo /usr/bin/tempo

# ╭──────────────────────────────────────────────────────────╮
# │ User                                                     │
# ╰──────────────────────────────────────────────────────────╯
ARG USER=tempo
RUN /usr/sbin/usermod -l $USER debian \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER debian \
 && /bin/passwd -d $USER \
 && rm -rf /home/debian

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
COPY scripts/container-version.sh /usr/bin/container-version
RUN chmod +x /usr/bin/container-version

# ╭――――――――――――――――――――╮
# │ HEALTH             │
# ╰――――――――――――――――――――╯
COPY health/tempo-check.sh /etc/container/health.d/tempo-running
RUN chmod +x /etc/container/health.d/tempo-running

# ╭――――――――――――――――――――╮
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
COPY services/tempo/run /etc/services.d/tempo/run
RUN chmod +x /etc/services.d/tempo/run

# Standard Tempo ports: 3200 (HTTP), 4317 (OTLP gRPC), 4318 (OTLP HTTP), 9095 (gRPC)
EXPOSE 3200 4317 4318 9095
WORKDIR /var/tempo
