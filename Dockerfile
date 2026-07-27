# syntax=docker/dockerfile:1.23
FROM alpine:3.24.1

# alpine-package: name=bash repo=main
ARG BASH_VERSION=5.3.9-r1
# alpine-package: name=bind-tools repo=main
ARG BIND_TOOLS_VERSION=9.20.26-r0
# alpine-package: name=catatonit repo=community
ARG CATATONIT_VERSION=0.2.1-r0
# alpine-package: name=coreutils repo=main
ARG COREUTILS_VERSION=9.11-r0
# alpine-package: name=curl repo=main
ARG CURL_VERSION=8.21.0-r0
# alpine-package: name=gettext-envsubst repo=main
ARG GETTEXT_ENVSUBST_VERSION=1.0-r0
# alpine-package: name=git repo=main
ARG GIT_VERSION=2.54.0-r0
# alpine-package: name=inetutils-telnet repo=community
ARG INETUTILS_VERSION=2.7-r0
# alpine-package: name=jq repo=main
ARG JQ_VERSION=1.8.1-r0
# alpine-package: name=openssl repo=main
ARG OPENSSL_VERSION=3.5.7-r0
# alpine-package: name=rsync repo=main
ARG RSYNC_VERSION=3.4.3-r1
# alpine-package: name=tzdata repo=main
ARG TZDATA_VERSION=2026c-r0
# alpine-package: name=xmlstarlet repo=community
ARG XMLSTARLET_VERSION=1.6.1-r2

# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.53.3

RUN apk add --no-cache \
  "bash=${BASH_VERSION}" \
  "bind-tools=${BIND_TOOLS_VERSION}" \
  "catatonit=${CATATONIT_VERSION}" \
  "coreutils=${COREUTILS_VERSION}" \
  "curl=${CURL_VERSION}" \
  "gettext-envsubst=${GETTEXT_ENVSUBST_VERSION}" \
  "git=${GIT_VERSION}" \
  "inetutils-telnet=${INETUTILS_VERSION}" \
  "jq=${JQ_VERSION}" \
  "openssl=${OPENSSL_VERSION}" \
  "rsync=${RSYNC_VERSION}" \
  "tzdata=${TZDATA_VERSION}" \
  "xmlstarlet=${XMLSTARLET_VERSION}"

# BuildKit automatically provides the target architecture for multi-platform builds.
ARG TARGETARCH

RUN case "${TARGETARCH}" in \
    amd64) yq_arch='amd64' ;; \
    arm64) yq_arch='arm64' ;; \
    *) echo "Unsupported TARGETARCH for yq: ${TARGETARCH}" >&2; exit 1 ;; \
  esac \
  && wget -O /usr/local/bin/yq \
    "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${yq_arch}" \
  && chmod +x /usr/local/bin/yq

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
