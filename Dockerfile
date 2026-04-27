# 基础镜像：官方 JDK17 (Ubuntu 22.04)
FROM eclipse-temurin:17-jdk-jammy

LABEL maintainer="your-email@example.com"
LABEL description="GitLab CI image with JDK17, Maven, Gradle, Node.js (offline install) and proxy configs"

# ==========================================
# 声明版本号变量，可外部传入
# ==========================================
ARG MAVEN_VERSION=3.9.6
ARG GRADLE_VERSION=8.7
ARG NODE_VERSION=20.11.1

# ==========================================
# 1. 安装常用系统工具
# ==========================================
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
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# 2. 复制离线安装包（版本由 ARG 决定）
# ==========================================
# COPY 指令需要再次声明 ARG 以使其可见
ARG MAVEN_VERSION
ARG GRADLE_VERSION
ARG NODE_VERSION

COPY apache-maven-${MAVEN_VERSION}-bin.tar.gz /tmp/
COPY gradle-${GRADLE_VERSION}-bin.zip /tmp/
COPY node-v${NODE_VERSION}-linux-x64.tar.xz /tmp/

# ==========================================
# 3. 离线安装 Maven / Gradle / Node.js
# ==========================================
# RUN 指令也需要再次声明 ARG
ARG MAVEN_VERSION
ARG GRADLE_VERSION
ARG NODE_VERSION

RUN tar xzf /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt \
    && mv /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && rm /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && unzip -q /tmp/gradle-${GRADLE_VERSION}-bin.zip -d /opt \
    && mv /opt/gradle-${GRADLE_VERSION} /opt/gradle \
    && rm /tmp/gradle-${GRADLE_VERSION}-bin.zip \
    && tar xJf /tmp/node-v${NODE_VERSION}-linux-x64.tar.xz -C /opt \
    && mv /opt/node-v${NODE_VERSION}-linux-x64 /opt/node \
    && rm /tmp/node-v${NODE_VERSION}-linux-x64.tar.xz

# ==========================================
# 4. 复制 Maven 与 npm 代理配置文件
# ==========================================
RUN mkdir -p /root/.m2
COPY settings.xml /root/.m2/settings.xml
COPY .npmrc /root/.npmrc

# ==========================================
# 5. 设置环境变量（路径固定，不依赖版本号）
# ==========================================
ENV MAVEN_HOME=/opt/maven
ENV GRADLE_HOME=/opt/gradle
ENV NODE_HOME=/opt/node

ENV PATH="${MAVEN_HOME}/bin:${GRADLE_HOME}/bin:${NODE_HOME}/bin:${PATH}"

# ==========================================
# 6. 验证安装
# ==========================================
RUN java -version \
    && mvn --version \
    && gradle --version \
    && node --version \
    && npm --version

# GitLab Runner 默认挂载代码位置
WORKDIR /builds
CMD ["/bin/bash"]
