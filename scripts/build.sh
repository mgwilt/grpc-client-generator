#!/bin/bash

set -e

# ================================
# Configuration Parameters
# ================================

# Default wire format mode is grpcwebtext. You can override it by passing the mode as the first argument.
WIRE_MODE=${1:-grpcwebtext}

# Validating the wire format mode
if [[ "$WIRE_MODE" != "grpcwebtext" && "$WIRE_MODE" != "grpcweb" ]]; then
    echo "Invalid wire format mode: $WIRE_MODE"
    echo "Allowed values are: grpcwebtext, grpcweb"
    exit 1
fi

# Define project directories
PROJECT_DIR=$(dirname "$0")/..
SRC_DIR="$PROJECT_DIR/src"
DIST_DIR="$PROJECT_DIR/dist"

# Docker image name
DOCKER_IMAGE="grpc-client-gen"

# ================================
# Pre-build Checks and Setup
# ================================
if ! command -v docker &> /dev/null
then
    echo "Docker could not be found. Please install Docker and try again."
    exit 1
fi

mkdir -p "$DIST_DIR/python"
mkdir -p "$DIST_DIR/swift"
mkdir -p "$DIST_DIR/javascript"
mkdir -p "$DIST_DIR/typescript"
mkdir -p "$DIST_DIR/kotlin"

# ================================
# Build Docker Image
# ================================
echo "Building Docker image: $DOCKER_IMAGE"
docker build -t "$DOCKER_IMAGE" .

# ================================
# Generate Python Client Library
# ================================
echo "Generating Python client library..."
mkdir -p "$DIST_DIR/python"
docker run --rm \
    -v "$SRC_DIR":/app/src \
    -v "$DIST_DIR":/app/dist \
    "$DOCKER_IMAGE" bash -c "\
        python3 -m grpc_tools.protoc -I./src \
        --python_out=./dist/python \
        --grpc_python_out=./dist/python \
        ./src/*.proto
    "

# ================================
# Generate Swift Client Library
# ================================
echo "Generating Swift client library..."
mkdir -p "$DIST_DIR/swift"
docker run --rm \
    -v "$SRC_DIR":/app/src \
    -v "$DIST_DIR":/app/dist \
    "$DOCKER_IMAGE" bash -c "\
        mkdir -p ./dist/swift && \
        protoc -I./src \
        --swift_out=./dist/swift \
        ./src/*.proto
    "

# ================================
# Generate Kotlin Client Library
# ================================
echo "Generating Kotlin client library..."
mkdir -p "$DIST_DIR/kotlin"
docker run --rm \
    -v "$SRC_DIR":/app/src \
    -v "$DIST_DIR":/app/dist \
    "$DOCKER_IMAGE" bash -c "\
        mkdir -p ./dist/kotlin && \
        protoc -I./src \
        --plugin=protoc-gen-grpckt=/app/protoc-gen-grpc-kotlin.sh \
        --kotlin_out=./dist/kotlin \
        --grpckt_out=./dist/kotlin \
        ./src/*.proto
    "


# ================================
# Generate JavaScript Client Library
# ================================
echo "Generating JavaScript client library..."
mkdir -p "$DIST_DIR/javascript"
docker run --rm \
    -v "$SRC_DIR":/app/src \
    -v "$DIST_DIR":/app/dist \
    "$DOCKER_IMAGE" bash -c "\
        mkdir -p ./dist/javascript && \
        protoc -I./src \
        --js_out=import_style=commonjs:./dist/javascript \
        --grpc-web_out=import_style=commonjs,mode=${WIRE_MODE}:./dist/javascript \
        ./src/*.proto
    "

# ================================
# Generate TypeScript Client Library
# ================================
echo "Generating TypeScript client library..."
mkdir -p "$DIST_DIR/typescript"
docker run --rm \
    -v "$SRC_DIR":/app/src \
    -v "$DIST_DIR":/app/dist \
    "$DOCKER_IMAGE" bash -c "\
        mkdir -p ./dist/typescript && \
        protoc -I./src \
        --grpc-web_out=import_style=typescript,mode=${WIRE_MODE}:./dist/typescript \
        ./src/*.proto
    "

# ================================
# Completion Message
# ================================
echo "Client libraries generated successfully in the ./dist directory."
echo "Wire format mode used: $WIRE_MODE"
echo "Generated client libraries:"
echo "  - Python: ./dist/python"
echo "  - Swift: ./dist/swift"
echo "  - JavaScript: ./dist/javascript"
echo "  - TypeScript: ./dist/typescript"
echo "  - Kotlin: ./dist/kotlin"
