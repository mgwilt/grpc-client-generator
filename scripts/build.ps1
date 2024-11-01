$ErrorActionPreference = 'Stop'

$WIRE_MODE = if ($args.Count -ge 1) { $args[0] } else { 'grpcwebtext' }

if ($WIRE_MODE -ne 'grpcwebtext' -and $WIRE_MODE -ne 'grpcweb') {
    Write-Host "Invalid wire format mode: $WIRE_MODE"
    Write-Host "Allowed values are: grpcwebtext, grpcweb"
    exit 1
}

$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SRC_DIR = Join-Path $PROJECT_DIR 'src'
$DIST_DIR = Join-Path $PROJECT_DIR 'dist'

$DOCKER_IMAGE = 'grpc-client-gen'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker could not be found. Please install Docker and try again."
    exit 1
}

New-Item -ItemType Directory -Force -Path (Join-Path $DIST_DIR 'python') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $DIST_DIR 'swift') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $DIST_DIR 'javascript') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $DIST_DIR 'typescript') | Out-Null

Write-Host "Building Docker image: $DOCKER_IMAGE"
docker build -t $DOCKER_IMAGE .

Write-Host "Generating Python client library..."
docker run --rm `
    -v "$SRC_DIR:/app/src" `
    -v "$DIST_DIR:/app/dist" `
    $DOCKER_IMAGE bash -c `
    "python3 -m grpc_tools.protoc -I./src `
    --python_out=./dist/python `
    --grpc_python_out=./dist/python `
    ./src/*.proto"

Write-Host "Generating Swift client library..."
docker run --rm `
    -v "$SRC_DIR:/app/src" `
    -v "$DIST_DIR:/app/dist" `
    $DOCKER_IMAGE bash -c `
    "mkdir -p ./dist/swift && `
    protoc -I./src `
    --swift_out=./dist/swift `
    ./src/*.proto"

Write-Host "Generating JavaScript client library..."
docker run --rm `
    -v "$SRC_DIR:/app/src" `
    -v "$DIST_DIR:/app/dist" `
    $DOCKER_IMAGE bash -c `
    "mkdir -p ./dist/javascript && `
    protoc -I./src `
    --js_out=import_style=commonjs:./dist/javascript `
    --grpc-web_out=import_style=commonjs,mode=$env:WIRE_MODE:./dist/javascript `
    ./src/*.proto"

Write-Host "Generating TypeScript client library..."
docker run --rm `
    -v "$SRC_DIR:/app/src" `
    -v "$DIST_DIR:/app/dist" `
    $DOCKER_IMAGE bash -c `
    "mkdir -p ./dist/typescript && `
    protoc -I./src `
    --grpc-web_out=import_style=typescript,mode=$env:WIRE_MODE:./dist/typescript `
    ./src/*.proto"

Write-Host "Client libraries generated successfully in the ./dist directory."
Write-Host "Wire format mode used: $WIRE_MODE"
Write-Host "Generated client libraries:"
Write-Host "  - Python: ./dist/python"
Write-Host "  - Swift: ./dist/swift"
Write-Host "  - JavaScript: ./dist/javascript"
Write-Host "  - TypeScript: ./dist/typescript"
