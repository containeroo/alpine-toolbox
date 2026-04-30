# syntax=docker/dockerfile:1.23
FROM alpine:3.23.4

# alpine-package: name=bash repo=main
ARG BASH_VERSION=5.3.3-r1
# alpine-package: name=bind-tools repo=main
ARG BIND_TOOLS_VERSION=9.20.22-r0
# alpine-package: name=coreutils repo=main
ARG COREUTILS_VERSION=9.8-r1
# alpine-package: name=curl repo=main
ARG CURL_VERSION=8.17.0-r1
# alpine-package: name=gettext repo=main
ARG GETTEXT_VERSION=0.24.1-r1
# alpine-package: name=git repo=main
ARG GIT_VERSION=2.52.0-r0
# alpine-package: name=inetutils-telnet repo=community
ARG INETUTILS_VERSION=2.6-r0
# alpine-package: name=jq repo=main
ARG JQ_VERSION=1.8.1-r0
# alpine-package: name=openssl repo=main
ARG OPENSSL_VERSION=3.5.6-r0
# alpine-package: name=tzdata repo=main
ARG TZDATA_VERSION=2026b-r0
# alpine-package: name=xmlstarlet repo=main
ARG XMLSTARLET_VERSION=1.6.1-r2
# alpine-package: name=rsync repo=main
ARG RSYNC_VERSION=3.4.2-r0
# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.53.2

# renovate: datasource=github-tags depName=openSUSE/catatonit extractVersion=^v(?<version>.*)$
ARG CATATONIT_VERSION=0.2.1

RUN apk add --no-cache \
  bash==${BASH_VERSION} \
  bind-tools==${BIND_TOOLS_VERSION} \
  coreutils==${COREUTILS_VERSION} \
  curl==${CURL_VERSION} \
  gettext==${GETTEXT_VERSION} \
  git==${GIT_VERSION} \
  inetutils-telnet==${INETUTILS_VERSION} \
  jq==${JQ_VERSION} \
  openssl==${OPENSSL_VERSION} \
  rsync==${RSYNC_VERSION} \
  tzdata==${TZDATA_VERSION} \
  xmlstarlet==${XMLSTARLET_VERSION}

# yq
RUN wget -O /usr/local/bin/yq \
  https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 \
  && chmod +x /usr/local/bin/yq

# catatonit (tiny init)
ADD https://github.com/openSUSE/catatonit/releases/download/v${CATATONIT_VERSION}/catatonit.x86_64 /usr/bin/catatonit
RUN chmod +x /usr/bin/catatonit

# ---- Runtime identity is chosen at build time ----
# default = non-root user 10001 with group 0 (OpenShift-friendly)
ARG RUNTIME_USER=10001
ARG RUNTIME_GROUP=0

# Writable work dir that works for both fixed UID and OpenShift arbitrary UID
ENV APP_HOME=/work
RUN mkdir -p "${APP_HOME}" \
  && chown -R ${RUNTIME_USER}:${RUNTIME_GROUP} "${APP_HOME}" \
  && chmod -R g=u "${APP_HOME}"
WORKDIR ${APP_HOME}

# Switch user (numeric IDs; no passwd entry required)
USER ${RUNTIME_USER}:${RUNTIME_GROUP}

STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/bin/catatonit", "--"]
# Replace with your real process if needed
CMD ["sleep", "infinity"]
