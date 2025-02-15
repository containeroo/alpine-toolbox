FROM alpine:3.20.3

# renovate: datasource=repology depName=alpine_3_20/bash versioning=loose
ARG BASH_VERSION=5.2.26-r0

# renovate: datasource=repology depName=alpine_3_20/curl versioning=loose
ARG CURL_VERSION=8.12.1-r0

# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.42.1

# renovate: datasource=repology depName=alpine_3_20/jq versioning=loose
ARG JQ_VERSION=1.7.1-r0

# renovate: datasource=repology depName=alpine_3_20/tzdata versioning=loose
ARG TZDATA_VERSION=2025a-r0

# renovate: datasource=repology depName=alpine_3_20/coreutils versioning=loose
ARG COREUTILS_VERSION=9.5-r2

# renovate: datasource=repology depName=alpine_3_20/gettext
ARG GETTEXT_VERSION=0.22.5-r0

# renovate: datasource=repology depName=alpine_3_20/openssl
ARG OPENSSL_VERSION=3.3.2-r2

# renovate: datasource=repology depName=alpine_3_20/xmlstarlet
ARG XMLSTARLET_VERSION=1.6.1-r2

#renovate: datasource=repology depName=alpine_3_20/rsync
ARG RSYNC_VERSION=3.4.0-r0

# renovate: datasource=repology depName=alpine_3_20/bind-tools
ARG BIND_TOOLS_VERSION=9.18.33-r0

# renovate: datasource=repology depName=alpine_3_20/inetutils-telnet
ARG INETUTILS_VERSION=2.5-r0

# renovate: datasource=github-tags depName=openSUSE/catatonit extractVersion=^v(?<version>.*)$
ARG CATATONIT_VERSION=0.2.0

RUN apk add --no-cache \
  bash==${BASH_VERSION} \
  curl==${CURL_VERSION} \
  jq==${JQ_VERSION} \
  tzdata==${TZDATA_VERSION} \
  coreutils==${COREUTILS_VERSION} \
  gettext==${GETTEXT_VERSION} \
  openssl==${OPENSSL_VERSION} \
  xmlstarlet==${XMLSTARLET_VERSION} \
  rsync==${RSYNC_VERSION} \
  bind-tools==${BIND_TOOLS_VERSION} \
  inetutils-telnet==${INETUTILS_VERSION} \
  && rm -rf /var/cache/apk/*

# download and install yq from GitHub
RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 && \
  chmod +x /usr/local/bin/yq

# download and install catatonit from GitHub
ADD https://github.com/openSUSE/catatonit/releases/download/v${CATATONIT_VERSION}/catatonit.x86_64 /usr/bin/catatonit
RUN chmod +x /usr/bin/catatonit

COPY forever.sh /usr/bin/forever
RUN chmod +x /usr/bin/forever

ENTRYPOINT ["/usr/bin/catatonit", "--"]
CMD [ "/usr/bin/forever" ]

