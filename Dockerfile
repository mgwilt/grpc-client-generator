# ================================
# Build Arguments
# ================================
ARG UBUNTU_VERSION=20.04

# ================================
# Base Image
# ================================
FROM ubuntu:${UBUNTU_VERSION}
ARG UBUNTU_VERSION=20.04

# ================================
# Environment Variables
# ================================
ENV TZ=America/Los_Angeles
ENV UBUNTU_VERSION=${UBUNTU_VERSION}
ENV PROTOC_VERSION=21.12
ENV SWIFT_VERSION=6.0.2
ENV SWIFT_PROTOBUF_VERSION=1.28.2
ENV GRPC_WEB_VERSION=1.5.0
ENV NODE_VERSION=20
ENV KOTLIN_GRPC_VERSION=1.4.1
ENV PATH="/usr/local/bin:/usr/local/nodejs/bin:${PATH}"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tzdata \
        build-essential \
        wget \
        unzip \
        apt-transport-https \
        software-properties-common \
        ca-certificates \
        gnupg \
        git \
        libssl-dev \
        libcurl4 \
        python3 \
        python3-pip \
        curl \
        openjdk-21-jdk \
    && rm -rf /var/lib/apt/lists/*

# ================================
# Setup Kotlin Dependencies
# ================================
ENV KOTLIN_GRPC_JAR=/usr/local/lib/protoc-gen-grpc-kotlin-${KOTLIN_GRPC_VERSION}-jdk8.jar

COPY ./scripts/protoc-gen-grpc-kotlin.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/protoc-gen-grpc-kotlin.sh && \
    wget -O "$KOTLIN_GRPC_JAR" https://repo1.maven.org/maven2/io/grpc/protoc-gen-grpc-kotlin/${KOTLIN_GRPC_VERSION}/protoc-gen-grpc-kotlin-${KOTLIN_GRPC_VERSION}-jdk8.jar && \
    chmod 644 "$KOTLIN_GRPC_JAR" && \
    wget -O "${KOTLIN_GRPC_JAR}.sha256" https://repo1.maven.org/maven2/io/grpc/protoc-gen-grpc-kotlin/${KOTLIN_GRPC_VERSION}/protoc-gen-grpc-kotlin-${KOTLIN_GRPC_VERSION}-jdk8.jar.sha256 && \
    echo "$(cat ${KOTLIN_GRPC_JAR}.sha256) ${KOTLIN_GRPC_JAR}" | sha256sum -c && \
    rm "${KOTLIN_GRPC_JAR}.sha256"

# ================================
# Install Node.js and npm
# ================================
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# ================================
# Install protoc
# ================================
RUN wget -O /tmp/protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    unzip /tmp/protoc.zip -d /usr/local && \
    chmod +x /usr/local/bin/protoc && \
    rm /tmp/protoc.zip

# ================================
# Install Protoc-JavaScript Plugin
# ================================
RUN npm install -g protoc-gen-js

# ================================
# Install gRPC Tools for Python
# ================================
RUN pip3 install --no-cache-dir grpcio grpcio-tools

# ================================
# Install Swift
# ================================
RUN UBUNTU_VERSION_NO_DOT=$(echo $UBUNTU_VERSION | tr -d '.') && \
    wget https://swift.org/builds/swift-${SWIFT_VERSION}-release/ubuntu${UBUNTU_VERSION_NO_DOT}/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-ubuntu${UBUNTU_VERSION}.tar.gz && \
    tar xzf swift-${SWIFT_VERSION}-RELEASE-ubuntu${UBUNTU_VERSION}.tar.gz -C /usr/share && \
    ln -s /usr/share/swift-${SWIFT_VERSION}-RELEASE-ubuntu${UBUNTU_VERSION}/usr/bin/swift /usr/bin/swift && \
    rm swift-${SWIFT_VERSION}-RELEASE-ubuntu${UBUNTU_VERSION}.tar.gz

# ================================
# Clone and Build swift-protobuf
# ================================
RUN git clone https://github.com/apple/swift-protobuf.git /tmp/swift-protobuf && \
    cd /tmp/swift-protobuf && \
    git checkout tags/${SWIFT_PROTOBUF_VERSION} && \
    swift build -c release && \
    cp .build/release/protoc-gen-swift /usr/local/bin/ && \
    rm -rf /tmp/swift-protobuf && \
    apt-get remove -y git && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# ================================
# Install gRPC-Web
# ================================
RUN wget -O /tmp/protoc-gen-grpc-web https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 && \
    wget -O /tmp/protoc-gen-grpc-web.sha256 https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64.sha256 && \
    HASH=$(awk '{print $1}' /tmp/protoc-gen-grpc-web.sha256) && \
    echo "${HASH}  /tmp/protoc-gen-grpc-web" | sha256sum -c - && \
    chmod +x /tmp/protoc-gen-grpc-web && \
    mv /tmp/protoc-gen-grpc-web /usr/local/bin/ && \
    rm /tmp/protoc-gen-grpc-web.sha256

WORKDIR /app
COPY src/ ./src/

CMD ["bash"]
