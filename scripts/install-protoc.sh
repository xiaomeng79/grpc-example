#!/bin/bash

set -eu

PB_REL="https://github.com/protocolbuffers/protobuf/releases"
HOSTOS=`uname -s | tr '[:upper:]' '[:lower:]'`
if [ "$HOSTOS" = "darwin" ]; then
    HOSTOS=osx
fi
HOSTARCH=`uname -m`
PROTOC_VERSION=${PROTOC_VERSION:-"3.14.0"}
PROTOC_FILE_NAME=protoc-${PROTOC_VERSION}-${HOSTOS}-${HOSTARCH}
PROTOC_FILE_ZIP=${PROTOC_FILE_NAME}.zip
PROTOC_PATH=${PROTOC_PATH:-"/tmp/protoc"}

#是否安装
install() {
if [ -z `which ${PROTOC_PATH}/bin/protoc` ]; then
  protoc-install
fi
}

protoc-install() {
  echo "安装目录:"${PROTOC_PATH}
  mkdir -p ${PROTOC_PATH}
  cd ${PROTOC_PATH}
  curl -LO ${PB_REL}/download/v${PROTOC_VERSION}/${PROTOC_FILE_ZIP}
  unzip -o ${PROTOC_FILE_ZIP} -d ${PROTOC_PATH}
  rm -rf ${PROTOC_FILE_ZIP}
  ${PROTOC_PATH}/bin/protoc --version
}

install
