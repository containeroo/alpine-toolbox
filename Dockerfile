FROM alpine:3.16.0

# renovate: datasource=repology depName=alpine_3_16/bash versioning=loose
ARG BASH_VERSION=5.1.16-r2

# renovate: datasource=repology depName=alpine_3_16/curl versioning=loose
ARG CURL_VERSION=7.83.1-r2

# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.25.3

# renovate: datasource=repology depName=alpine_3_16/jq versioning=loose
ARG JQ_VERSION=1.6-r1

# renovate: datasource=repology depName=alpine_3_16/tzdata versioning=loose
ARG TZDATA_VERSION=2022a-r0

# renovate: datasource=repology depName=alpine_3_16/coreutils versioning=loose
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
