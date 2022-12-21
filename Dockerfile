FROM alpine:3.17.0

# renovate: datasource=repology depName=alpine_3_17/bash versioning=loose
ARG BASH_VERSION=5.2.15-r0

# renovate: datasource=repology depName=alpine_3_17/curl versioning=loose
ARG CURL_VERSION=7.87.0-r0

# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.30.6

# renovate: datasource=repology depName=alpine_3_17/jq versioning=loose
ARG JQ_VERSION=1.6-r2

# renovate: datasource=repology depName=alpine_3_17/tzdata versioning=loose
ARG TZDATA_VERSION=2022f-r1

# renovate: datasource=repology depName=alpine_3_17/coreutils versioning=loose
ARG COREUTILS_VERSION=9.1-r0

RUN apk add --no-cache \
  bash==${BASH_VERSION} \
  curl==${CURL_VERSION} \
  jq==${JQ_VERSION} \
  tzdata==${TZDATA_VERSION} \
  coreutils==${COREUTILS_VERSION} \
  && rm -rf /var/cache/apk/*

RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 && \
  chmod +x /usr/local/bin/yq
