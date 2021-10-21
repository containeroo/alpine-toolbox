FROM alpine:3.14.2

# renovate: datasource=repology depName=alpine_3_14/bash versioning=loose
ARG BASH_VERSION=5.1.4-r0

# renovate: datasource=repology depName=alpine_3_14/curl versioning=loose
ARG CURL_VERSION=7.79.1-r0

# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.13.5

# renovate: datasource=repology depName=alpine_3_14/jq versioning=loose
ARG JQ_VERSION=1.6-r1

# renovate: datasource=repology depName=alpine_3_14/tzdata versioning=loose
ARG TZDATA_VERSION=2021d-r0

# renovate: datasource=repology depName=alpine_3_14/coreutils versioning=loose
ARG COREUTILS_VERSION=8.32-r2

RUN apk add --no-cache \
  bash==${BASH_VERSION} \
  curl==${CURL_VERSION} \
  jq==${JQ_VERSION} \
  tzdata==${TZDATA_VERSION} \
  coreutils==${COREUTILS_VERSION} \
  rm -rf /var/cache/apk/*

RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq
