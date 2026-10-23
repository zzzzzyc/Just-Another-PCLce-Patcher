# Just Another PCLce Patcher

[![License: WTFPL](https://img.shields.io/badge/license-WTFPL-blue.svg)](LICENSE)

[下载运行包](https://github.com/zzzzzyc/Just-Another-PCLce-Patcher/releases/latest/download/Just-Another-PCLce-Patcher.zip)

给 PCL CE 松松绑：解除地区和正版档案限制，关闭遥测，藏掉组织名称提示。

把原版 PCL CE EXE 放进 `Original/`，运行 `Start-PCL.bat` 选好配置，以后双击 `PCL.exe`。所有选项默认开启，配置 BAT 用完默认自删。

适配 PCL CE 2.15.1 x64，需要 .NET 10 桌面运行时。

自己编译：装好 .NET SDK 8+，运行 `./build.ps1`，产物在 `dist/`。

使用 [Harmony](https://github.com/pardeike/Harmony)（MIT）。
