# 基础镜像：官方 JDK17 (Ubuntu 22.04)
FROM eclipse-temurin:17-jdk-jammy

LABEL maintainer="your-email@example.com"
LABEL description="GitLab CI image with JDK17, Maven, Gradle, Node.js (offline install) and proxy configs"

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
# 2. 离线安装 Maven (假设安装包 apache-maven-3.9.6-bin.tar.gz 已在构建目录)
# ==========================================
COPY apache-maven-3.9.6-bin.tar.gz /tmp/
RUN tar xzf /tmp/apache-maven-3.9.6-bin.tar.gz -C /opt \
    && mv /opt/apache-maven-3.9.6 /opt/maven \
    && rm /tmp/apache-maven-3.9.6-bin.tar.gz

# ==========================================
# 3. 离线安装 Gradle (假设 gradle-8.7-bin.zip 已在构建目录)
# ==========================================
COPY gradle-8.7-bin.zip /tmp/
RUN unzip -q /tmp/gradle-8.7-bin.zip -d /opt \
    && mv /opt/gradle-8.7 /opt/gradle \
    && rm /tmp/gradle-8.7-bin.zip

# ==========================================
# 4. 离线安装 Node.js (假设 node-v20.11.1-linux-x64.tar.xz 已在构建目录)
# ==========================================
COPY node-v20.11.1-linux-x64.tar.xz /tmp/
RUN tar xJf /tmp/node-v20.11.1-linux-x64.tar.xz -C /opt \
    && mv /opt/node-v20.11.1-linux-x64 /opt/node \
    && rm /tmp/node-v20.11.1-linux-x64.tar.xz

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
