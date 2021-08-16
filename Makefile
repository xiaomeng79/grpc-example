# 全局定义

# 包定义
PROJECT_NAME=grpc-example
PROJECT_PACKAGE=github.com/xiaomeng79/${PROJECT_NAME}
PACKAGE_VERSION=0.1.0

# 构建定义
GO_PATH=$(shell go env GOPATH)
GO_VERSION=$(shell go version)
GOPROXY=https://goproxy.cn,direct
GO111MODULE=on
GIT_COMMIT=$(shell git rev-parse --short HEAD 2> /dev/null || true)
BUILD_TIME=$(shell date --utc --rfc-3339 ns 2> /dev/null | sed -e 's/ /T/')
BUILD_DIR=target

# 中间生成文件和目录
TESTS_COV_FILE=$(BUILD_DIR)/tests/coverage.txt
GENERATE_TAGS_DIR=$(BUILD_DIR)/gen
PROTOC_DIR=srv/proto
PROTOC_JSON_DIR=$(BUILD_DIR)/protoc-json

# 依赖工具
GRPC_GATEWAY_VERSION=v2@v2.1.0
PROTOC_PATH?=${BUILD_DIR}/protoc


# 顶层规则
.PHONY: all package clean

all: install fmt lint test  build

# 安装依赖的工具
.PHONY: install-tools ${BUILD_DIR}/gen/go-tools

install: install-tools ${BUILD_DIR}/gen/go-tools

install-tools: ${BUILD_DIR}/gen/install-protoc

${BUILD_DIR}/gen/go-tools:
	@echo "安装go的工具"
	go get \
		google.golang.org/protobuf/cmd/protoc-gen-go \
		golang.org/x/tools/cmd/stringer \
		github.com/golangci/golangci-lint/cmd/golangci-lint \
		google.golang.org/grpc/cmd/protoc-gen-go-grpc && \
	go get github.com/go-bindata/go-bindata/... && \
	go get github.com/elazarl/go-bindata-assetfs/... && \
	go get	github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v2.1.0 && \
	go get	github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v2.1.0 && \
	mkdir -p `dirname $@` && touch $@

${BUILD_DIR}/gen/install-protoc:
	@echo "安装protoc工具..."
	chmod +x ./scripts/install-protoc.sh && PROTOC_PATH=${PROTOC_PATH} ./scripts/install-protoc.sh && mkdir -p `dirname $@` && touch $@

# 构建
.PHONY: build-srv

build: build-srv
	@go mod tidy

package: build
	@echo "打包……"
	rm -rf ${BUILD_DIR}/${PROJECT_NAME}
	mkdir -p ${BUILD_DIR}/${PROJECT_NAME}
	cp -r \
		${BUILD_DIR}/${PACKAGE_DIRNAME}/.
	tar -C ${BUILD_DIR} -czvf ${BUILD_DIR}/${PACKAGE_DIRNAME}.tar.gz ${BUILD_DIR}/bin

clean:
	rm -rf ${BUILD_DIR}

# test
.PHONY: fmt lint test

fmt :
	@echo "格式化代码..."
	@gofmt -l -w ./

lint: generate
	golangci-lint run --timeout 5m ./...

test: generate
	mkdir -p `dirname ${TESTS_COV_FILE}`
	go test -cover -coverprofile=${TESTS_COV_FILE} ./...
	go tool cover -func ${TESTS_COV_FILE}

# build
.PHONY: build-srv

build-srv: generate
	@echo "构建${PROJECT_NAME}……"
	mkdir -p ${BUILD_DIR}/bin
	go build -ldflags \
		" \
		-w \
		-X '${PROJECT_PACKAGE}/srv/conf.Version=${ENGINE_VERSION}' \
		-X '${PROJECT_PACKAGE}/srv/conf.GoVersion=${GO_VERSION}' \
		-X '${PROJECT_PACKAGE}/srv/conf.GitCommit=${GIT_COMMIT}' \
		-X '${PROJECT_PACKAGE}/srv/conf.BuiltTime=${BUILD_TIME}' \
		" \
		-o ${BUILD_DIR}/bin/${PROJECT_NAME} ./cmd/main.go

# benchmarks
.PHONY: benchmarks

benchmarks: generate
	go test --bench=. ./...

# generate
.PHONY: generate go-generate protoc-generate swagger-generate

generate: protoc-generate swagger-generate go-generate

# go-generate执行的都是不耗时的构建动作，可以每次构建都执行一次。耗时的构建动作，需要用依赖规则，避免无谓的重复执行。
go-generate:
	go generate ./...

protoc-generate: ${GENERATE_TAGS_DIR}/protoc.gen

${GENERATE_TAGS_DIR}/protoc.gen: ${PROTOC_DIR}/*.proto
	@echo "处理proto文件……"
	rm -rf ${PROTOC_JSON_DIR} && mkdir -p ${PROTOC_JSON_DIR}
	rm -rf `dirname $<`/gen
	${PROTOC_PATH}/bin/protoc -I. \
		-I${GO_PATH}/pkg/mod/github.com/grpc-ecosystem/grpc-gateway/${GRPC_GATEWAY_VERSION}/third_party/googleapis \
		-I${GO_PATH}/pkg/mod/github.com/grpc-ecosystem/grpc-gateway/${GRPC_GATEWAY_VERSION}/ \
		-I${PROTOC_PATH}/include \
		--go-grpc_out . \
        --openapiv2_out ${PROTOC_JSON_DIR} \
        --grpc-gateway_out . \
		--go_out . $^
	mkdir -p `dirname $@` && touch $@

swagger-generate: ${PROTOC_DIR}/gen/swaggerui/bindata.go ${PROTOC_DIR}/gen/swagger/bindata.go

${PROTOC_DIR}/gen/swaggerui/bindata.go: third_party/swagger-ui/dist/*
	@echo "生成swagger ui资源……"
	mkdir -p `dirname $@`
	go-bindata-assetfs -pkg swaggerui -o $@  `dirname $<`/...

${PROTOC_DIR}/gen/swagger/bindata.go: ${GENERATE_TAGS_DIR}/protoc.gen
	@echo "处理swagger json文件..."
	mkdir -p `dirname $@`
	go-bindata-assetfs -pkg swagger -o $@ ${PROTOC_JSON_DIR}/...
