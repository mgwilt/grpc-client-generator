#!/bin/sh

# Make the path configurable via environment variable
KOTLIN_GRPC_JAR=${KOTLIN_GRPC_JAR:-"/usr/local/lib/protoc-gen-grpc-kotlin-1.4.1-jdk8.jar"}

if [ ! -f "$KOTLIN_GRPC_JAR" ]; then
    echo "Error: Kotlin gRPC JAR not found at $KOTLIN_GRPC_JAR" >&2
    exit 1
fi

exec java -jar "$KOTLIN_GRPC_JAR" "$@"