#!/bin/bash

set -e

PROJECT_DIR=$(dirname "$0")/..
SRC_DIR="$PROJECT_DIR/src"
DIST_DIR="$PROJECT_DIR/dist"

if ! command -v docker &> /dev/null
then
    echo "Docker could not be found. Please install Docker and try again."
    exit 1
fi

mkdir -p "$DIST_DIR/python"
mkdir -p "$DIST_DIR/swift"

docker build -t grpc-client-gen .

docker run --rm -v "$SRC_DIR":/app/src -v "$DIST_DIR":/app/dist grpc-client-gen bash -c "\
    python3 -m grpc_tools.protoc -I./src --python_out=./dist/python --grpc_python_out=./dist/python ./src/*.proto
"

docker run --rm -v "$SRC_DIR":/app/src -v "$DIST_DIR":/app/dist grpc-client-gen bash -c "\
    mkdir -p ./dist/swift && \
    protoc -I./src \
    --swift_out=./dist/swift \
    ./src/*.proto
"

echo "Client libraries generated successfully in the ./dist directory."
