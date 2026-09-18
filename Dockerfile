# syntax=docker/dockerfile:1

# ---------- 构建阶段：固定 Flutter 版本编译 Web 静态文件 ----------
FROM debian:bookworm-slim AS build

# Flutter 版本与 pubspec.yaml 中的 Dart SDK 约束保持一致（3.47.4 内置 Dart 3.13.3）
ARG FLUTTER_VERSION=3.47.4

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C /opt \
    && git config --global --add safe.directory /opt/flutter
ENV PATH=/opt/flutter/bin:$PATH

WORKDIR /app

# 先拷贝依赖描述，利用 Docker 层缓存
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# 部署在子路径下时可传入：docker build --build-arg BASE_HREF=/todolist/
ARG BASE_HREF=/
RUN flutter build web --release --base-href="$BASE_HREF"

# ---------- 运行阶段：nginx 托管静态文件 ----------
FROM nginx:stable-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
CMD ["nginx", "-g", "daemon off;"]
