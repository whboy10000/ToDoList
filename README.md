# ToDOList

[![Build Packages](https://github.com/whboy10000/ToDoList/actions/workflows/build.yml/badge.svg)](https://github.com/whboy10000/ToDoList/actions/workflows/build.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.4-02569B?logo=flutter)](https://docs.flutter.dev/release/release-notes)
[![Dart](https://img.shields.io/badge/Dart-%5E3.13.3-0175C2?logo=dart)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-4F6BFF)](#%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B)
[![Image](https://img.shields.io/badge/GHCR-ghcr.io%2Fwhboy10000%2Ftodolist-2496ED?logo=docker)](https://github.com/whboy10000/ToDoList/pkgs/container/todolist)

**一套 Flutter 代码，同时运行在手机、桌面与浏览器上的全平台任务清单应用。**

无需注册、没有后端服务器，所有数据保存在本地；支持自然语言一句话快速建任务、
番茄专注计时、统计打卡与深浅色主题，覆盖从「随手记下」到「专注完成」的完整闭环。

## 功能特性

### 任务管理

- **完整任务模型**：标题、备注、到期日期/时间、四级优先级（无 / 低 / 中 / 高，带颜色标记）、多标签、子任务（可逐项勾选）、彩色分类（内置「工作 / 生活 / 学习」，可自建）
- **重复任务**：支持每天 / 每周 / 每月，勾选完成后自动按规则生成下一次任务
- **状态流转**：待办 → 已完成 / 已归档 / 回收站；回收站支持恢复、单条彻底删除与一键清空
- **撤销机制**：增删改等操作保留最近 20 步历史，SnackBar 内可即时撤销
- **多种排序**：智能排序、按到期时间、按优先级、按创建时间、手动拖拽排序
- **智能分组**：待办自动归入「已过期 / 今天 / 明天 / 本周 / 以后 / 无日期」，过期任务红色提醒
- **搜索与过滤**：支持按标题、备注、标签全文搜索，可按分类筛选，待办 / 已完成 / 全部视图切换

### 自然语言快速输入

在底部输入框用一句话即可完成带全部属性的任务创建：

```
明天 下午3点 交季度报告 @工作 !高 #重要 #汇报 每周
```

| 类型 | 语法示例 |
|---|---|
| 日期 | `今天` `明天` `后天` `大后天` `3天后` `周三` / `星期三` `下周一` `9月20日`（已过则自动算明年） |
| 时间 | `15:30` `3点` `3点半` `3点15分` `下午3点` `晚上8点半` `中午12点`（`下午` 与 `3点` 分开写也可识别） |
| 优先级 | `!高` `!中` `!低`，等价写法 `!!!` `!!` |
| 分类 | `@工作`（分类不存在时自动创建） |
| 标签 | `#健身`（可带多个） |
| 重复 | `每天` / `每日` `每周` `每月` |

只写时间不写日期时，若该时刻今天已过则自动顺延到明天。应用内输入框旁的「语法帮助」按钮也可随时查看。

### 番茄专注

- 经典三模式：**专注 25 分钟 / 短休息 5 分钟 / 长休息 15 分钟**，开始、暂停、重置
- 可关联一个待办任务，完成的番茄钟自动累计到该任务
- 倒计时结束弹窗提醒，模式间一键切换

### 统计仪表盘

- **连续打卡天数**：今天或昨天起向前连续每天至少完成 1 个任务
- **近 7 天完成柱状图**：纯 Flutter 自绘，无第三方图表库
- **分类待办分布**：进度条展示各分类待办数量
- 今日完成数、累计完成数、过期任务快捷入口

### 个性化与效率

- Material 3 设计，主题色可换（默认 `#4F6BFF`），浅色 / 深色 / 跟随系统
- 桌面端 **`Ctrl/Cmd + K`** 打开命令面板：新建任务、切换主题、快速跳转页面、搜索并直接勾选任务
- 桌面端 **`Ctrl/Cmd + N`** 快速新建任务
- 自适应布局：宽屏使用 NavigationRail、窄屏使用底部导航，桌面 / 平板 / 手机一套界面

### 数据与隐私

- 纯本地应用：数据以 JSON 存储在系统本地（`shared_preferences`），**不联网、不上传、无账号**
- 支持一键导出 JSON（复制到剪贴板）与粘贴导入，方便换机迁移或自行备份
- Web 端数据存储在浏览器 localStorage 中，清理浏览器数据会同时清除任务，建议定期导出备份

## 技术栈

| 分类 | 选型 |
|---|---|
| 框架 | Flutter 3.47.4（Dart ^3.13.3），Material 3 |
| 状态管理 | `ChangeNotifier` + `ListenableBuilder`（无额外状态管理框架） |
| 本地存储 | [`shared_preferences`](https://pub.dev/packages/shared_preferences)，单 JSON 快照 |
| 其他依赖 | `flutter_localizations`、`intl`（Material 组件中文本地化） |
| Web 部署 | 多阶段 Docker 构建（Flutter 编译 → nginx 托管静态文件） |
| CI/CD | GitHub Actions：六平台构建 + GHCR 镜像发布 |

## 项目结构

```
todolist/
├── lib/
│   ├── main.dart                  # 应用入口、主题与多语言配置
│   ├── models/
│   │   └── task.dart              # Task / Subtask / Category 模型与 JSON 序列化
│   ├── pages/
│   │   ├── home_page.dart         # 自适应外壳（导航栏 + 快捷键）
│   │   ├── tasks_page.dart        # 任务列表、分组、搜索、快速输入
│   │   ├── task_edit_sheet.dart   # 任务新建/编辑底部弹层
│   │   ├── focus_page.dart        # 番茄专注计时
│   │   ├── stats_page.dart        # 统计仪表盘（自绘柱状图）
│   │   └── settings_page.dart     # 外观、分类、数据导入导出
│   ├── services/
│   │   ├── app_state.dart         # 全局状态：CRUD、撤销、统计、持久化
│   │   ├── nlp_parser.dart        # 自然语言快速输入解析器
│   │   └── palette.dart           # 分类/主题色板
│   └── widgets/
│       ├── command_palette.dart   # Ctrl/Cmd+K 命令面板
│       └── task_tile.dart         # 任务卡片
├── test/
│   └── nlp_and_state_test.dart    # 解析器与状态逻辑单元测试
├── android/ ios/ macos/ windows/ linux/ web/   # 各平台宿主工程
├── Dockerfile                     # Web 端镜像（Flutter + nginx 多阶段）
├── docker/nginx.conf              # 镜像内 nginx 配置（gzip/缓存/SPA 回退）
├── docker-compose.yml             # 一键部署 Web 端
└── .github/workflows/build.yml    # 六平台 CI 构建工作流
```

## 快速开始

环境要求：已安装 Flutter 3.47.4 或更高的 stable 版本（`flutter doctor` 无缺失项）。

```bash
flutter pub get       # 安装依赖
flutter run           # 连接设备/模拟器后运行
flutter test          # 运行单元测试
```

指定平台运行：

```bash
flutter run -d chrome     # Web
flutter run -d macos      # macOS（需 flutter config --enable-macos-desktop）
flutter run -d windows    # Windows
flutter run -d linux      # Linux（需先安装 ninja-build、libgtk-3-dev）
flutter run -d android    # Android
flutter run -d ios        # iOS（仅 macOS + Xcode）
```

## 本地打包

在 macOS 上可使用一键脚本产出 DMG / APK / 未签名 IPA：

```bash
./build_all.sh        # 产物输出到 releases/ 目录
```

也可按平台单独构建：

| 平台 | 命令 | 产物 |
|---|---|---|
| Android | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| iOS | `flutter build ios --release --no-codesign`（macOS） | Xcode 工程 / 自行打包未签名 IPA |
| macOS | `flutter build macos --release`（macOS） | `build/macos/Build/Products/Release/ToDOList.app` |
| Windows | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| Linux | `flutter build linux --release`（需 `ninja-build`、`libgtk-3-dev`） | `build/linux/x64/release/bundle/` |
| Web | `flutter build web --release` | `build/web/` 静态文件 |

> iOS 构建未配置 Apple 开发者证书，CI 与脚本产出的均为**未签名 IPA**，
> 需使用 Xcode（免费 Apple ID 即可）或其他签名工具重签名后才能安装到真机。

## Web 端 Docker 部署

Web 端以 Docker 镜像发布（多阶段构建：Flutter 编译静态文件 + nginx 托管），
推送 `v*` 标签后 GitHub Actions 会自动构建并推送到 GHCR：

- 最新版：`ghcr.io/whboy10000/todolist:latest`
- 指定版本：`ghcr.io/whboy10000/todolist:v0.1.1`

### docker compose（推荐）

```bash
docker compose up -d                            # 启动后访问 http://服务器IP:8080
docker compose pull && docker compose up -d     # 更新到最新版
```

### docker run

```bash
docker run -d \
  --name todolist-web \
  -p 8080:80 \
  --restart unless-stopped \
  ghcr.io/whboy10000/todolist:latest
```

> 镜像为公开镜像，无需登录即可拉取。
> 如之后将包改为私有，需先登录：
> `echo <GH_TOKEN> | docker login ghcr.io -u whboy10000 --password-stdin`

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

## CI/CD（GitHub Actions）

工作流定义见 [`.github/workflows/build.yml`](.github/workflows/build.yml)，共 6 个并行任务：

| 任务 | 运行环境 | 产物 |
|---|---|---|
| Windows 安装包 | windows-latest | `ToDoList-windows-x64.zip` |
| Linux 安装包 | ubuntu-latest | `ToDoList-linux-x64.tar.gz` |
| macOS DMG | macos-latest | `ToDoList-macos.dmg` |
| Android APK | ubuntu-latest | `app-release.apk` |
| iOS（未签名） | macos-latest | `ToDoList-ios-unsigned.ipa` |
| Web Docker 镜像 | ubuntu-latest | 推送至 `ghcr.io/whboy10000/todolist`（含 GHA 层缓存） |
| 发布 Release | ubuntu-latest | 仅标签触发：自动创建 GitHub Release 并附加上述 5 个安装包 |

触发方式：

- **推送 `v*` 标签**（如 `git tag v0.1.1 && git push --tags`）：构建全部产物，Docker 镜像同时打版本号与 `latest` 标签，并在 [Releases](https://github.com/whboy10000/ToDoList/releases) 页面自动发布安装包（含自动生成的更新日志）
- **Actions 页面手动触发**（Run workflow）：构建全部产物，安装包仅作为 Artifacts 保留；Docker 镜像打短 SHA 标签

除 Release 资产外，每次运行的安装包也会保留在运行记录页底部的 **Artifacts** 区域（登录 GitHub 后下载），
或使用命令行：

```bash
gh run download <RUN_ID>     # 例如 gh run download 35333849522
```

## 路线图

- Web 端 PWA 离线缓存（Service Worker）与桌面通知
- 任务到期本地通知（移动 / 桌面端）
- 重复任务「工作日」等更灵活的规则
