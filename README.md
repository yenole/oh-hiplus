# Hi时刻

Hi时刻是一款面向 HarmonyOS 手机的车机辅助应用，提供 HiCar 连接入口、车机应用浏览、个人设置及使用帮助。项目使用 ArkTS / ArkUI 开发，并通过 `libohos.so` 调用原生能力获取车机应用、启动投屏 Agent 和进行用户授权。

> 当前应用面向手机设备；车机连接和应用列表等功能依赖兼容的 HiCar 环境及项目原生库。部分首页展示内容目前为静态演示数据，详见「当前实现说明」。

## 功能概览

- **爱车**：设置无线调试端口，检查 HiCar 状态并进入投屏/悬浮窗相关流程。
- **应用**：读取车机应用列表，按导航、音乐、视频和工具分类展示；支持下拉刷新及本地缓存。
- **个人中心**：通过公众号授权登录，查看个人信息，并进入设置、反馈和关于页面。
- **投屏设置**：配置自动打开悬浮窗、保持屏幕常亮及操作提示选项。
- **系统设置**：配置无线调试端口、应用列表自动刷新，清理应用缓存或恢复部分默认设置。
- **意见反馈**：整理反馈内容并复制到剪贴板，按页面指引发送给公众号「Hi时刻」。

## 技术栈与环境

- HarmonyOS / OpenHarmony 应用工程，ArkTS 与 ArkUI
- DevEco Studio 及其 HarmonyOS SDK、Hvigor、Node.js 和 Java 运行环境
- 设备端调试与安装使用 `hdc`
- 原生接口由 `entry` 模块引用的 `libohos.so` 提供

构建配置当前指定 HarmonyOS SDK `6.0.2(22)`，应用版本为 `4.0.1`。请使用与工程配置兼容的 DevEco Studio 和 SDK。

## 项目结构

```text
.
├── AppScope/                  # 应用级配置
├── entry/
│   └── src/main/ets/
│       ├── components/        # 页面组件
│       ├── entryability/      # 主 Ability
│       ├── launcherability/   # 横屏启动 Ability
│       ├── pages/             # 首页、设置、反馈、关于等页面
│       ├── utils/             # HiCar Dock 等工具
│       └── window/            # 悬浮窗及应用窗口
├── signatures/                # 本地签名材料（请妥善保管）
├── build-profile.json5        # 产品、SDK 与签名构建配置
├── Makefile                   # 构建、安装、启动及日志快捷命令
└── oh-package.json5           # 工程依赖配置
```

