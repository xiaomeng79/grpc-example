#!/bin/bash

set -eu
PROTOC_PATH=${PROTOC_PATH:-"/tmp/protoc"}
GOPATH=${GOPATH:-"$HOME/go"}

protoc-gen() {
      mkdir -p api/proto/gen
      mkdir -p api/proto/gen/swaggerjson
  		for f in ./api/proto/*.proto; do \
		    if [ -f $f ];then \
		      ${PROTOC_PATH}/bin/protoc -I. \
			   -I${GOPATH}/pkg/mod/github.com/grpc-ecosystem/grpc-gateway/v2@v2.1.0/third_party/googleapis \
			   -I${GOPATH}/pkg/mod/github.com/grpc-ecosystem/grpc-gateway/v2@v2.1.0/ \
			   -I${PROTOC_PATH}/include \
         --go-grpc_out . \
         --openapiv2_out api/proto/gen/swaggerjson/ \
         --grpc-gateway_out . \
         --go_out . $f; \
         echo compiled protoc: $f; \
        fi \
		done \
}
protoc-gen