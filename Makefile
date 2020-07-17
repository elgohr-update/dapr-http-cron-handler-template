RELEASE_VERSION  =v0.1.1
SERVICE_NAME    ?=$(notdir $(shell pwd))
DOCKER_USERNAME ?=$(DOCKER_USER)

.PHONY: mod test run debug build dapr event image show imagerun lint clean, tag
all: test

tidy: ## Updates the go modules and vendors all dependencies 
	go mod tidy
	go mod vendor

test: tidy ## Tests the entire project 
	go test -count=1 -race ./...

build: tidy ## Builds local release binary
	CGO_ENABLED=0 go build -a -tags netgo -mod vendor -o bin/$(SERVICE_NAME) .

debug: ## Runs uncompiled code it in Dapr in debug mode
	dapr run --app-id $(SERVICE_NAME) \
	     --protocol http \
	     --app-port 8080 \
	     --components-path ./config \
	     --log-level debug \
	     go run *.go

run: build ## Builds binary and runs it in Dapr
	dapr run --app-id $(SERVICE_NAME) \
		 --app-port 8080 \
		 --protocol http \
		 --port 3500 \
         --components-path ./config \
         bin/$(SERVICE_NAME) 

image: tidy ## Builds and publish docker image 
	docker build -t "$(DOCKER_USERNAME)/$(SERVICE_NAME):$(RELEASE_VERSION)" .
	docker push "$(DOCKER_USERNAME)/$(SERVICE_NAME):$(RELEASE_VERSION)"

lint: ## Lints the entire project 
	golangci-lint run --timeout=3m

tag: ## Creates release tag 
	git tag $(RELEASE_VERSION)
	git push origin $(RELEASE_VERSION)

clean: ## Cleans up generated files 
	go clean
	rm -fr ./bin
	rm -fr ./vendor

reset: clean ## Resets go modules 
	rm go.*

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk \
		'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'