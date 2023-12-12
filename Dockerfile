FROM alpine:3.19.0

# renovate: datasource=repology depName=alpine_3_19/bash versioning=loose
ARG BASH_VERSION=5.2.21-r0

# renovate: datasource=repology depName=alpine_3_19/curl versioning=loose
ARG CURL_VERSION=8.5.0-r0

# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.31.2

# renovate: datasource=repology depName=alpine_3_19/jq versioning=loose
ARG JQ_VERSION=1.7-r2

# renovate: datasource=repology depName=alpine_3_19/tzdata versioning=loose
ARG TZDATA_VERSION=2023c-r1

# renovate: datasource=repology depName=alpine_3_19/coreutils versioning=loose
ARG COREUTILS_VERSION=9.4-r1

# renovate: datasource=repology depName=alpine_3_19/gettext
ARG GETTEXT_VERSION=0.22.3-r0

# renovate: datasource=repology depName=alpine_3_19/openssl
ARG OPENSSL_VERSION=3.1.4-r2

RUN apk add --no-cache \
  bash==${BASH_VERSION} \
  curl==${CURL_VERSION} \
  jq==${JQ_VERSION} \
  tzdata==${TZDATA_VERSION} \
  coreutils==${COREUTILS_VERSION} \
  gettext==${GETTEXT_VERSION} \
  openssl==${OPENSSL_VERSION} \
  && rm -rf /var/cache/apk/*

RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 && \
  chmod +x /usr/local/bin/yq
