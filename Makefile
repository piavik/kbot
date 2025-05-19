APP := $(shell basename -s .git $(shell git remote get-url origin))
VERSION := $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
REGISTRY := ghcr.io/piavik

#defaults
TARGETOS ?= linux
TARGETARCH ?= amd64

.DELETE_ON_ERROR:

format:
	@gofmt -s -w .

vet:
	@go vet ./...

lint: vet
	@which golangci-lint > /dev/null || (curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.1.6)
	@golangci-lint run ./...

test:
	@go test -v 

deps:
	@#which go > /dev/null || wget https://go.dev/dl/go1.24.3.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.24.3.linux-amd64.tar.gz && set PATH=${PATH}:/usr/local/go/bin; export PATH
	@go mod tidy
	@go mod download

build: format deps vet test
	@echo "Creating docker image for TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH}"
	@CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
	 go build -v -o ${APP}-${TARGETOS}-${TARGETARCH} \
	 -ldflags "-X="github.com/piavik/kbot/cmd.appVersion=${VERSION}

image:
	@docker build . -t ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH} \
			--build-arg TARGETARCH=${TARGETARCH} \
			--build-arg TARGETOS=${TARGETOS} \
			--build-arg VERSION=${VERSION}

linux_amd64:
	@$(MAKE) build TARGETOS=linux TARGETARCH=amd64 --no-print-directory

linux_arm64:
	@$(MAKE) build TARGETOS=linux TARGETARCH=arm64 --no-print-directory

linux: linux_amd64 linux_arm64 ;

macos_amd64:
	@$(MAKE) build TARGETOS=darwin TARGETARCH=amd64 --no-print-directory

macos_arm64:
	@$(MAKE) build TARGETOS=darwin TARGETARCH=arm64 --no-print-directory

macos: macos_amd64 macos_arm64 ;

windows_amd64:
	@$(MAKE) build TARGETOS=windows TARGETARCH=amd64 --no-print-directory

windows_arm64:
	@$(MAKE) build TARGETOS=windows TARGETARCH=arm64 --no-print-directory

windows: windows_amd64 windows_arm64 ;

build_all: linux macos windows ;

push:
	@docker push ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

clean:
	@rm -rf kbot*
	@docker rmi -f ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH} 2>/dev/null || true

release: clean test build image push ; 
