# syntax=docker/dockerfile:1

# ---------- 构建阶段：Flutter 编译 Web 静态文件 ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build
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
