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

## 开发与构建

推荐使用 DevEco Studio 打开项目根目录，等待依赖同步完成，并确认工程能找到 `entry` 所需的原生库 `entry/libs/libohos.so`。仓库的 `Makefile` 默认使用以下 DevEco Studio 安装位置：

```text
/Applications/DevEco-Studio.app/Contents
```

如果安装路径不同，可在执行命令时指定 `DEVECO_HOME`：

```sh
make build DEVECO_HOME="/你的/DevEco-Studio.app/Contents"
```

常用命令：

```sh
make help       # 查看命令说明
make build      # 构建签名 HAP
make clean      # 清理构建输出与缓存
make rebuild    # 清理后重新构建
make install    # 安装已构建的 HAP
make launch     # 在设备上启动应用
make deploy     # 构建、安装并启动，然后持续查看应用日志
make logs       # 查看设备上的 hiplus/JSAPP 日志
```

连接多台设备时可指定设备 ID：

```sh
make install DEVICE=<设备ID>
make deploy DEVICE=<设备ID>
```

默认产物路径为：

```text
entry/build/default/outputs/default/entry-default-signed.hap
```

`make install` 只安装已有产物，不会触发构建；`make deploy` 会在构建和启动后进入日志跟踪。退出日志跟踪可按 `Ctrl-C`。

## 设备使用提示

1. 在兼容的 HarmonyOS 手机和 HiCar 车机环境中安装应用。
2. 按车机/系统提供的无线调试说明获取调试端口，并在首页首次提示或「我的 → 系统设置」中填写端口。
3. 手机与车机需满足对应连接条件；从首页进入投屏流程前，应用会检查 HiCar 连接状态。
4. 应用列表通过原生接口读取。若关闭「启动时刷新应用列表」，页面会优先展示本地缓存；也可下拉刷新。
5. 登录及反馈流程通过公众号「Hi时刻」完成，反馈页面会引导用户复制内容后自行发送。

应用清单声明了网络、HiCar、虚拟屏幕和系统悬浮窗等权限。实际可用性仍取决于设备、系统授权、HiCar 状态和原生服务支持。

## 当前实现说明

- 首页爱车卡片中的续航（`520 km`）、温度（`24°C`）以及个人中心中的统计数字是静态展示值，不代表实时车辆或使用数据。
- 投屏设置页面的连接状态目前按静态「已准备好」展示，不等同于实时连接检测。
- 意见反馈页面会生成复制内容并展示公众号指引；页面本身没有直接提交反馈到服务器。
- `Makefile` 中 `dev` 命令依赖额外安装的 `cargo-watch`。
- `build-profile.json5` 中的签名路径配置为本机绝对路径。其他开发者需在本地配置自己的签名材料和路径，不应提交私钥、密码或个人签名文件。

## 测试

工程包含 `entry/src/test` 与 `entry/src/ohosTest` 下的单元及设备测试。可在 DevEco Studio 中运行对应测试套件；也可使用 IDE 的构建与测试工具检查目标 SDK 下的 ArkTS 编译结果。

## 版本与应用信息

- 应用名称：Hi时刻
- Bundle：`com.yenole.hiplus`
- 当前版本：`4.0.1`
- 主模块：`entry`
