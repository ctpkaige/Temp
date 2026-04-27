# 基于官方 OpenJDK 17 (Ubuntu 22.04)，已自带 JDK
FROM eclipse-temurin:17-jdk-jammy

LABEL maintainer="your-email@example.com"
LABEL description="GitLab CI image with JDK17, Maven, Gradle, Node.js and common utilities"

# 可自定义的版本
ENV MAVEN_VERSION=3.9.6
ENV GRADLE_VERSION=8.7
ENV NODE_MAJOR=20

# --- 1. 安装常用系统工具 ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    unzip \
    zip \
    jq \
    python3 \
    python3-pip \
    openssh-client \
    ca-certificates \
    gnupg \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# --- 2. 安装 Maven ---
RUN mkdir -p /opt && \
    curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    -o /tmp/maven.tar.gz && \
    tar xzf /tmp/maven.tar.gz -C /opt && \
    mv /opt/apache-maven-${MAVEN_VERSION} /opt/maven && \
    rm /tmp/maven.tar.gz

# --- 3. 安装 Gradle ---
RUN curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    -o /tmp/gradle.zip && \
    unzip -d /opt /tmp/gradle.zip && \
    mv /opt/gradle-${GRADLE_VERSION} /opt/gradle && \
    rm /tmp/gradle.zip

# --- 4. 安装 Node.js (使用 NodeSource 官方脚本) ---
RUN set -uex; \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -; \
    apt-get install -y nodejs; \
    rm -rf /var/lib/apt/lists/*

# --- 5. 统一设置环境变量 ---
ENV MAVEN_HOME=/opt/maven
ENV GRADLE_HOME=/opt/gradle
ENV PATH="${MAVEN_HOME}/bin:${GRADLE_HOME}/bin:${PATH}"

# --- 6. 验证安装 ---
RUN java -version && \
    mvn --version && \
    gradle --version && \
    node --version && \
    npm --version

# GitLab 运行器默认挂载代码到 /builds，提前设好工作目录
WORKDIR /builds
CMD ["/bin/bash"]
