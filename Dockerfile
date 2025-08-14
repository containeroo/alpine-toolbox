FROM alpine:3.22.1

# renovate: datasource=repology depName=alpine_3_22/bash versioning=loose
ARG BASH_VERSION=5.2.37-r0

# renovate: datasource=repology depName=alpine_3_22/curl versioning=loose
ARG CURL_VERSION=8.14.1-r1

# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.47.1

# renovate: datasource=repology depName=alpine_3_22/jq versioning=loose
ARG JQ_VERSION=1.8.0-r0

# renovate: datasource=repology depName=alpine_3_22/tzdata versioning=loose
ARG TZDATA_VERSION=2025b-r0

# renovate: datasource=repology depName=alpine_3_22/coreutils versioning=loose
ARG COREUTILS_VERSION=9.7-r1

# renovate: datasource=repology depName=alpine_3_22/gettext
ARG GETTEXT_VERSION=0.24.1-r0

# renovate: datasource=repology depName=alpine_3_22/openssl
ARG OPENSSL_VERSION=3.5.1-r0

# renovate: datasource=repology depName=alpine_3_22/xmlstarlet
ARG XMLSTARLET_VERSION=1.6.1-r2

#renovate: datasource=repology depName=alpine_3_22/rsync
ARG RSYNC_VERSION=3.4.1-r0

# renovate: datasource=repology depName=alpine_3_22/bind-tools
ARG BIND_TOOLS_VERSION=9.20.11-r0

# renovate: datasource=repology depName=alpine_3_22/inetutils-telnet
ARG INETUTILS_VERSION=2.6-r0

# renovate: datasource=github-tags depName=openSUSE/catatonit extractVersion=^v(?<version>.*)$
ARG CATATONIT_VERSION=0.2.1

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

