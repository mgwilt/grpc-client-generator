# gRPC Client Generator

This tool simply takes proto files in ./src and generates client stubs for them. Hunting down and installing all of these dependencies got old fast.

## Client Output Languages

| Language   | Support |
| ---------- | :-----: |
| Python     |    ✅    |
| Swift      |    ✅    |
| JavaScript |    ✅    |
| TypeScript |    ✅    |
| Java       |    ❌    |
| Kotlin     |    ✅    |
| Go         |    ❌    |
| .NET       |    ❌    |

Working on adding all of the above.

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
    ./scripts/build.sh [wire-format-mode]
    ```

    ```powershell
    ./scripts/build.ps1 -WireMode [wire-format-mode]
    ```

   Wire format modes:
   - `grpcwebtext` (default)
   - `grpcweb`
   
   For more information on wire format modes, see [grpc-web](https://github.com/grpc/grpc-web)
   
## Usage

Place your `.proto` files in the `src/` directory. Running the build script will generate the client stubs in the `dist/` directory:

- `dist/python`: Python client
- `dist/swift`: Swift client
- `dist/javascript`: JavaScript client
- `dist/typescript`: TypeScript client
- `dist/kotlin`: Kotlin client

Each language-specific directory will contain the generated gRPC client code ready for use in your projects.