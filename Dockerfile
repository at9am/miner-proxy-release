# syntax=docker/dockerfile:1.7

FROM alpine:3.21
ARG TARGETARCH=amd64
RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -g 10001 miner \
    && adduser -D -H -u 10001 -G miner miner \
    && mkdir -p /app/data /tmp \
    && chown -R miner:miner /app /tmp
WORKDIR /app
COPY miner-proxy-linux-${TARGETARCH} /app/miner-proxy
RUN chmod 0555 /app/miner-proxy
USER 10001:10001
VOLUME ["/app/data"]
STOPSIGNAL SIGTERM
ENTRYPOINT ["/app/miner-proxy"]
CMD ["--config", "/app/config.yaml"]
