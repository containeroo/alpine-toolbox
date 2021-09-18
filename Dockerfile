FROM curlimages/curl:7.78.0 as builder

FROM alpine:3.14.2

# renovate: datasource=github-releases depName=stedolan/jq versioning=loose extractVersion=^jq-(?<version>.*)$
ARG JQ_VERSION=1.6

# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.13.0

RUN apk add --no-cache bash brotli brotli-dev libssh2 nghttp2-dev && \
    rm -fr /var/cache/apk/*

COPY --from=builder ["/usr/lib/libcurl.so*", "/usr/lib/"]
COPY --from=builder "/usr/bin/curl" "/usr/bin/curl"

COPY --from=builder "/cacert.pem" "/cacert.pem"
ENV CURL_CA_BUNDLE="/cacert.pem"

RUN wget -O /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 && \
    chmod +x /usr/local/bin/jq

RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq
