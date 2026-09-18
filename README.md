# ToDOList

全平台任务清单应用（Flutter）：支持 Windows / macOS / Linux / Android / iOS / Web。

## 功能

- 任务增删改查、子任务、备注、标签、分类、优先级、到期提醒
- 自然语言快速输入：`明天 下午3点 交报告 @工作 !高 #重要 每周`
- 重复任务、番茄专注计时、统计仪表盘与连续打卡
- 回收站 / 归档 / 撤销、深浅色主题与主题色、数据导入导出
- 桌面端 `Ctrl/Cmd + K` 命令面板、自适应布局

## 打包

```bash
./build_all.sh        # macOS 上一键产出 DMG / APK / IPA
flutter build web --release   # Web 静态包（也可直接使用下方 Docker 镜像）
```

Windows / Linux 通过 GitHub Actions（`.github/workflows/build.yml`）打包。

## Web 端 Docker 部署

Web 端以 Docker 镜像发布（多阶段构建：Flutter 编译静态文件 + nginx 托管），
推送 `v*` 标签后 GitHub Actions 会自动构建并推送到 GHCR：

- 最新版：`ghcr.io/whboy10000/todolist:latest`
- 指定版本：`ghcr.io/whboy10000/todolist:v0.1.0`

### docker compose（推荐）

```bash
docker compose up -d        # 启动后访问 http://服务器IP:8080
docker compose pull && docker compose up -d   # 更新到最新版
```

### docker run

```bash
docker run -d \
  --name todolist-web \
  -p 8080:80 \
  --restart unless-stopped \
  ghcr.io/whboy10000/todolist:latest
```

> 镜像默认为私有，拉取前需先登录：
> `echo <GH_TOKEN> | docker login ghcr.io -u whboy10000 --password-stdin`
> （也可在 GitHub Packages 设置中将包改为 Public 免登录拉取）

### 本地自行构建

```bash
docker build -t todolist-web .
docker run -d -p 8080:80 todolist-web

# 部署在子路径（如 https://example.com/todolist/）时：
docker build --build-arg BASE_HREF=/todolist/ -t todolist-web .
```

### Nginx 反向代理（HTTPS）

镜像内已监听 80 端口并配置好 gzip、静态资源缓存与 SPA 回退，
前置 Nginx / Caddy 反代到 `127.0.0.1:8080` 即可启用 HTTPS。
