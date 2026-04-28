# 基础镜像：官方 JDK17 (Ubuntu 22.04)
FROM eclipse-temurin:17-jdk-jammy

LABEL maintainer="tp.cheng@samsung.com"
LABEL description="GitLab CI image with JDK17, Maven, Gradle, Node.js (offline install) and proxy configs"

# ================= 版本参数 =================
ARG MAVEN_VERSION=3.9.15
ARG GRADLE_VERSION=9.4.1
ARG NODE_VERSION=20.20.2

# ==========================================
# 1. 安装常用系统工具 (仍为在线安装，但基础镜像通常预装了 curl/wget)
# 如确需完全离线，可去掉此步骤或使用预构建基础镜像
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
# 2. 离线安装 Maven
# ==========================================
COPY apache-maven-${MAVEN_VERSION}-bin.tar.gz /tmp/
RUN tar xzf /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt \
    && mv /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && rm /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz

# ==========================================
# 3. 离线安装 Gradle
# ==========================================
COPY gradle-${GRADLE_VERSION}-bin.zip /tmp/
RUN unzip -q /tmp/gradle-${GRADLE_VERSION}-bin.zip -d /opt \
    && mv /opt/gradle-${GRADLE_VERSION} /opt/gradle \
    && rm /tmp/gradle-${GRADLE_VERSION}-bin.zip

# ==========================================
# 4. 离线安装 Node.js
# ==========================================
COPY node-v${NODE_VERSION}-linux-x64.tar.xz /tmp/
RUN tar xJf /tmp/node-v${NODE_VERSION}-linux-x64.tar.xz -C /opt \
    && mv /opt/node-v${NODE_VERSION}-linux-x64 /opt/node \
    && rm /tmp/node-v${NODE_VERSION}-linux-x64.tar.xz

# ==========================================
# 5. 以文件形式覆盖 Maven 与 npm 代理配置
# ==========================================
# 提前创建目标目录
RUN mkdir -p /root/.m2

# 将提前准备好的 settings.xml 和 .npmrc 复制到容器中
COPY settings.xml /root/.m2/settings.xml
COPY .npmrc /root/.npmrc

# ==========================================
# 6. 统一设置环境变量
# ==========================================
ENV MAVEN_HOME=/opt/maven
ENV GRADLE_HOME=/opt/gradle
ENV NODE_HOME=/opt/node

ENV PATH="${MAVEN_HOME}/bin:${GRADLE_HOME}/bin:${NODE_HOME}/bin:${PATH}"

# ==========================================
# 7. 验证安装
# ==========================================
RUN java -version \
    && mvn --version \
    && gradle --version \
    && node --version \
    && npm --version

# GitLab Runner 默认挂载代码位置
WORKDIR /builds
CMD ["/bin/bash"]
