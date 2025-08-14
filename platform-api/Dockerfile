FROM golang:1.22-alpine AS builder

WORKDIR /app

RUN apk update && apk add --no-cache git ca-certificates tzdata && \
    apk upgrade && \
    rm -rf /var/cache/apk/*

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o platform-api ./cmd/server

FROM gcr.io/distroless/static-debian11:nonroot

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /app/platform-api /platform-api

USER nonroot:nonroot

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/platform-api", "--health-check"] || exit 1

EXPOSE 8080

ENTRYPOINT ["/platform-api"]