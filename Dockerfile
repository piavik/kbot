FROM --platform=$BUILDPLATFORM quay.io/projectquay/golang:1.24 as builder

WORKDIR /go/src/app
COPY . .
ARG TARGETARCH
RUN make build

FROM scratch
WORKDIR /
COPY --from=builder /go/src/app/kbot* ./kbot
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs
ENTRYPOINT ["./kbot", "start"]
