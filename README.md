# Just Another PCLce Patcher

[![Release](https://img.shields.io/github/v/release/zzzzzyc/Just-Another-PCLce-Patcher)](https://github.com/zzzzzyc/Just-Another-PCLce-Patcher/releases/latest)
[![License: WTFPL](https://img.shields.io/badge/license-WTFPL-blue.svg)](LICENSE)

给 PCL CE 松松绑。通过 .NET Startup Hook 和 Harmony，在启动时应用你选好的修改。

**[下载运行包](https://github.com/zzzzzyc/Just-Another-PCLce-Patcher/releases/latest/download/Just-Another-PCLce-Patcher.zip)** · [反馈问题](https://github.com/zzzzzyc/Just-Another-PCLce-Patcher/issues)

## 能做什么

- 解除游戏本体下载的地区限制。
- 解除正版档案门槛，允许创建离线和第三方登录档案。
- 关闭普通遥测：首次询问的原文加删除线，两个按钮都改成“不同意”。
- 关闭联机遥测。
- 隐藏需要输入开发组织名称才能关闭的 PCL CE 提示。

以上功能都能在菜单中单独开关，默认全部开启。

## 怎么用

需要 Windows x64 和 **.NET 10 桌面运行时**。当前适配 **PCL CE 2.15.1 x64**。

1. 下载运行包，解压到新文件夹。
2. 双击 `Start-PCL.bat`。同目录的原版 PCL CE EXE 会自动移入 `Original/`；找不到时，输入 `D` 从官方 Release 下载适配版本。也可以提前把原版放进 `Original/`。
3. 输入数字切换选项，回车保存并启动。PCL 打开后，配置脚本自动退出。
4. 以后直接双击 `PCL.exe`，会沿用之前的设置。

默认会清理 BAT、PS1、README 和两个许可证文件，可在菜单第 6 项关闭。日常使用保留 `PCL.exe`、`Hook.dll`、`0Harmony.dll`、`Hook.ini` 和 `Original/` 里的原版程序。

## 修改配置

重新解压 `Start-PCL.bat` 和 `Start-PCL.ps1` 即可再次打开菜单。也可以直接编辑 `Hook.ini`，`1` 开启、`0` 关闭，重启 PCL 生效：

```ini
UnlockRegion=1
UnlockProfiles=1
DisableTelemetry=1
DisableLobbyTelemetry=1
HideCommunityHint=1
```

配置项依次对应上面的五个功能。删除配置文件会恢复全部开启。

## 编译

在 Windows 上安装 .NET SDK 8 或更高版本，运行 `./build.ps1`，产物位于 `dist/`。

源码使用 [WTFPL](LICENSE)。依赖 [Harmony](https://github.com/pardeike/Harmony)（MIT），运行包附带其许可文本。
