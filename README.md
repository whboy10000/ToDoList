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
flutter build web --release   # Web 静态包
```

Windows / Linux 通过 GitHub Actions（`.github/workflows/build.yml`）打包。
