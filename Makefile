APP := $(shell basename -s .git $(shell git remote get-url origin))
VERSION := $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
REGISTRY := ghcr.io/piavik

#defaults
TARGETOS ?= linux
TARGETARCH ?= amd64
BIN_DIR := .

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

# install dependencies
deps:
	@#which go > /dev/null || wget https://go.dev/dl/go1.24.3.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.24.3.linux-amd64.tar.gz && set PATH=${PATH}:/usr/local/go/bin; export PATH
	@go mod tidy
	@go mod download

# build binary for TARGETOS:TARGETARCH platform
build: format deps vet test
	@echo "Compiling binary executable for TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH}"
	@CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
	 go build -v -o ${BIN_DIR}/kbot \
	 -ldflags "-X="github.com/piavik/kbot/cmd.appVersion=${VERSION}

# build docker image for TARGETOS:TARGETARCH platform
image:
	@echo "Creating docker image for TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH}"
	@docker build . -t ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH} \
			--build-arg TARGETARCH=${TARGETARCH} \
			--build-arg TARGETOS=${TARGETOS} \
			--build-arg VERSION=${VERSION}

# build preset TARGETOS:TARGETARCH 
linux_amd64:
	@$(eval TARGETOS=linux)
	@$(eval TARGETARCH=amd64)
	@$(MAKE) build TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH} BIN_DIR=./${TARGETOS}/${TARGETARCH} --no-print-directory

linux_arm64:
	@$(eval TARGETOS=linux)
	@$(eval TARGETARCH=arm64)
	@$(MAKE) build TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH} BIN_DIR=./${TARGETOS}/${TARGETARCH} --no-print-directory

darwin_amd64:
	@$(eval TARGETOS=darwin)
	@$(eval TARGETARCH=amd64)
	@$(MAKE) build TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH} BIN_DIR=./${TARGETOS}/${TARGETARCH} --no-print-directory

darwin_arm64:
	@$(eval TARGETOS=darwin)
	@$(eval TARGETARCH=arm64)
	@$(MAKE) build TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH} BIN_DIR=./${TARGETOS}/${TARGETARCH} --no-print-directory

windows_amd64:
	@$(eval TARGETOS=windows)
	@$(eval TARGETARCH=amd64)
	@$(MAKE) build TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH} BIN_DIR=./${TARGETOS}/${TARGETARCH} --no-print-directory

windows_arm64:
	@$(eval TARGETOS=windows)
	@$(eval TARGETARCH=arm64)
	@$(MAKE) build TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH} BIN_DIR=./${TARGETOS}/${TARGETARCH} --no-print-directory

linux: linux_amd64 linux_arm64 ;

darwin: darwin_amd64 darwin_arm64 ;

windows: windows_amd64 windows_arm64 ;

build_all: linux darwin windows ;

push:
	@docker push ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

clean:
	@rm -rf kbot*
	@for dir in linux darwin windows; do rm -rf $$dir; done
	@docker rmi -f ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH} 2>/dev/null || true
