param (
    [Parameter(Position=0, Mandatory=$false)]
    [ValidateSet("grpcwebtext", "grpcweb")]
    [string]$WireMode = "grpcwebtext"
)

# ================================
# Define Project Directories
# ================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectDir = Resolve-Path (Join-Path $ScriptDir "..")
$SrcDir = Join-Path $ProjectDir "src"
$DistDir = Join-Path $ProjectDir "dist"

# Convert Windows paths to Unix-style paths for Docker compatibility
$SrcDirUnix = $SrcDir -replace '\\', '/'
$DistDirUnix = $DistDir -replace '\\', '/'

$DockerImage = "grpc-client-gen"

# ================================
# Pre-build Checks and Setup
# ================================
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker could not be found. Please install Docker and try again." -ForegroundColor Red
    exit 1
}

$SubDirectories = @("python", "swift", "javascript", "typescript")
foreach ($Dir in $SubDirectories) {
    $Path = Join-Path $DistDir $Dir
    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
        Write-Host "Created directory: $Path" -ForegroundColor Green
    }
}

# ================================
# Build Docker Image
# ================================
Write-Host "Building Docker image: $DockerImage" -ForegroundColor Cyan
Push-Location $ProjectDir
docker build -t $DockerImage .
Pop-Location
Write-Host "Docker image built successfully." -ForegroundColor Green

# ================================
# Generate Python Client Library
# ================================
Write-Host "Generating Python client library..." -ForegroundColor Cyan
docker run --rm `
    -v "${SrcDirUnix}:/app/src" `
    -v "${DistDirUnix}:/app/dist" `
    $DockerImage bash -c 'python3 -m grpc_tools.protoc -I./src --python_out=./dist/python --grpc_python_out=./dist/python ./src/*.proto'
Write-Host "Python client library generated at ./dist/python" -ForegroundColor Green

# ================================
# Generate Swift Client Library
# ================================
Write-Host "Generating Swift client library..." -ForegroundColor Cyan
docker run --rm `
    -v "${SrcDirUnix}:/app/src" `
    -v "${DistDirUnix}:/app/dist" `
    $DockerImage bash -c 'mkdir -p ./dist/swift && protoc -I./src --swift_out=./dist/swift ./src/*.proto'
Write-Host "Swift client library generated at ./dist/swift" -ForegroundColor Green

# ================================
# Generate Kotlin Client Library
# ================================
Write-Host "Generating Kotlin client library..." -ForegroundColor Cyan
docker run --rm `
    -v "${SrcDirUnix}:/app/src" `
    -v "${DistDirUnix}:/app/dist" `
    $DockerImage bash -c 'mkdir -p ./dist/kotlin && KOTLIN_GRPC_JAR=/usr/local/lib/protoc-gen-grpc-kotlin-1.4.1-jdk8.jar && test -f $KOTLIN_GRPC_JAR && protoc -I./src --kotlin_out=./dist/kotlin --plugin=protoc-gen-grpckt=/usr/local/bin/protoc-gen-grpc-kotlin.sh --grpckt_out=./dist/kotlin ./src/*.proto'
Write-Host "Kotlin client library generated at ./dist/kotlin" -ForegroundColor Green


# ================================
# Generate JavaScript Client Library
# ================================
Write-Host "Generating JavaScript client library..." -ForegroundColor Cyan
docker run --rm `
    -v "${SrcDirUnix}:/app/src" `
    -v "${DistDirUnix}:/app/dist" `
    $DockerImage bash -c "mkdir -p ./dist/javascript && protoc -I./src --js_out=import_style=commonjs:./dist/javascript --grpc-web_out=import_style=commonjs,mode=${WireMode}:./dist/javascript ./src/*.proto"
Write-Host "JavaScript client library generated at ./dist/javascript" -ForegroundColor Green

# ================================
# Generate TypeScript Client Library
# ================================
Write-Host "Generating TypeScript client library..." -ForegroundColor Cyan
docker run --rm `
    -v "${SrcDirUnix}:/app/src" `
    -v "${DistDirUnix}:/app/dist" `
    $DockerImage bash -c "mkdir -p ./dist/typescript && protoc -I./src --grpc-web_out=import_style=typescript,mode=${WireMode}:./dist/typescript ./src/*.proto"
Write-Host "TypeScript client library generated at ./dist/typescript" -ForegroundColor Green

# ================================
# Completion Message
# ================================
Write-Host "`nClient libraries generated successfully in the ./dist directory." -ForegroundColor Yellow
Write-Host "Wire format mode used: $WireMode" -ForegroundColor Yellow
Write-Host "Generated client libraries:" -ForegroundColor Yellow
Write-Host "  - Python: ./dist/python" -ForegroundColor Yellow
Write-Host "  - Swift: ./dist/swift" -ForegroundColor Yellow
Write-Host "  - JavaScript: ./dist/javascript" -ForegroundColor Yellow
Write-Host "  - TypeScript: ./dist/typescript`n" -ForegroundColor Yellow
