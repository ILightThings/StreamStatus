# Use an intermediate container for initial building
FROM golang:1.16-buster AS builder
RUN apt-get update && apt-get install -y upx ca-certificates --no-install-recommends && apt-get clean && rm -rf /var/lib/apt/lists/*

# Use go modules and don't let go packages call C code
ENV GO111MODULE=on CGO_ENABLED=0
WORKDIR /build
COPY . .
RUN GOOS=linux GOARCH=amd64 go build -mod=vendor -ldflags="-s -w" -o StreamStatus ./...

# Compress the binary and verify the output using UPX
# h/t @FiloSottile/Filippo Valsorda: https://blog.filippo.io/shrink-your-go-binaries-with-this-one-weird-trick/
RUN upx --ultra-brute /build/StreamStatus && upx -t /build/StreamStatus
RUN mkdir /data

# Copy the contents of /dist to the root of a scratch containter
FROM scratch
COPY --chown=0:0 --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --chown=0:0 --from=builder /build/StreamStatus /
WORKDIR /
EXPOSE 3000
ENTRYPOINT ["/StreamStatus"]
