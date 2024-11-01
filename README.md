# gRPC Client Generator

A tool to generate gRPC client libraries in Python and Swift from Protocol Buffer definitions.

## Prerequisites

- [Docker](https://www.docker.com/get-started)

## Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/your-repo/grpc-client-generator.git
    cd grpc-client-generator
    ```

2. Build and run the Docker container to generate client libraries:

    ```bash
    ./scripts/build.sh
    ```

## Usage

Place your `.proto` files in the `src/` directory. Running the build script will generate the client libraries in the `dist/` directory:

- `dist/python`: Python client libraries
- `dist/swift`: Swift client libraries