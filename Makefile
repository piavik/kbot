APP=$(shell basename $(shell git remote get-url origin))
KBOT_VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
REGISTRY=piavik
TARGETOS=linux
TARGETARCH=$(shell dpkg --print-architecture)

format:
	gofmt -s -w ./

lint:
	go vet

test:
	go test -v 

prerequisites:
	go get

build: format prerequisites
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o kbot -ldflags "-X="github.com/piavik/kbot/cmd.appVersion=${KBOT_VERSION}

image:
	docker build . -t ${REGISTRY}/${APP}:${KBOT_VERSION}-${TARGETARCH}

push:
	docker push ${REGISTRY}/${APP}:${KBOT_VERSION}-${TARGETARCH}

clean:
	rm -rf kbot
