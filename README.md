# Desperados - Wanted Dead or Alive 中文汉化修复

《赏金奇兵：西部通缉令》Steam 汉化补丁，包含主游戏和 Demo，支持自选游戏目录、安装前备份和统一还原。适用于 **Steam Build 2959430**（主程序 desperados.exe）。

## 下载与版本选择

在 [v2.3.0 发布页](https://github.com/newbility/Desperados_Wanted_Dead_or_Alive_Chinese/releases/tag/v2.3.0) 选择一种完整包。两个 ZIP 都包含主游戏和 Demo。请下载 ZIP 附件，GitHub 自动生成的 Source code 不含汉化资源。

| 字体版本 | 完整安装包 |
|---|---|
| 原汉化字体 | [Desperados_Original_Font_v2.3.0.zip](https://github.com/newbility/Desperados_Wanted_Dead_or_Alive_Chinese/releases/download/v2.3.0/Desperados_Original_Font_v2.3.0.zip) |
| 思源黑体 | [Desperados_SourceHan_v2.3.0.zip](https://github.com/newbility/Desperados_Wanted_Dead_or_Alive_Chinese/releases/download/v2.3.0/Desperados_SourceHan_v2.3.0.zip) |

v2.3.0 修复部分显卡的文字黑块与空白问题，将两套字体的字库纹理宽度降到 4096 像素并保留字形及字距。[SHA256SUMS.txt](https://github.com/newbility/Desperados_Wanted_Dead_or_Alive_Chinese/releases/download/v2.3.0/SHA256SUMS.txt)

## 字体实机对比

[v2.3.0 快捷键列表与 Demo 截图](docs/FONT_COMPARISON.md#v230-黑框修复实机对比)。下方保留以往版本的主菜单对比。

这里的“原版”指原汉化字体，并非未汉化的英文版。下面都是实际游戏截图，点击图片可查看原尺寸；没有替换截图中的文字。

| 原汉化字体 | 思源黑体 v2.2.1 |
|---|---|
| ![原汉化字体主菜单](docs/images/original-menu.png) | ![思源黑体菜单优化版](docs/images/sourcehan-v2.2.1-menu.png) |

完整对比见 [字体对比与版本截图](docs/FONT_COMPARISON.md)，包含原字体、v2.2.0、v2.2.1 三版菜单、设置菜单及游戏内提示。早期合成预览不作为本页的实机对比。

## 安装、升级与还原

1. 关闭游戏并完整解压所选 ZIP，双击 **Install.cmd**。
2. 在窗口中选择 **包含 desperados.exe 的游戏根目录**；支持其他盘符、中文和空格路径。
3. 安装器校验游戏版本与资源，备份原文件后安装主游戏及 Demo 汉化。
4. 从 Steam 启动：下方 Wanted Dead or Alive 区域的英美旗帜进入主游戏，上方 Demo Mission 区域的英美旗帜进入 Demo。

已有旧汉化时，先用旧包的 **Restore.cmd** 还原，再安装新版。安装器会校验并备份原程序和 31 个资源，再应用对应的渲染修复。要撤销 v2.3.0，请运行新版包中的 **Restore.cmd**，并保留该包的 installation.json 和 backups。

完整说明见 [使用说明](installer/使用说明.md)。仓库中的 installer 目录仅供查看和维护，请用 Release 的完整包安装。

## 汉化内容与本次更新

- 主游戏 1086 条对白、任务说明和提示，139 条菜单及状态文字。
- 13 套中文字库、中文主菜单背景与两张任务结算画面。
- 12 段过场视频、117 条中文字幕，保留原音轨。
- Demo 的 139 条菜单文字、6 页中文操作指南，复用 49 条中文对白及任务提示。
- 思源黑体版保留原有行高、字符前进宽度及拉丁字形，覆盖 1292 个映射汉字。
- v2.2.1 相对 v2.2.0 只调整四套菜单按钮字库：中文 em 从 27 缩至 22，描边收细，图集上下至少各留 5 像素；其他 27 个资源逐字节相同。

v2.3.0 包含 31 个汉化资源及游戏字体渲染修复。图片和过场视频中已经固化的文字沿用原汉化素材，不随实时字库改变。

## 验证与已知边界

v2.3.0 已在本机验证两套字体的快捷键列表，最终 ZIP 通过安装、旧版升级和原版还原检查。反馈玩家的 AMD 显卡和开场对白待复测。

早期版本已核验字库字符覆盖、原字距和拉丁像素、菜单上下边距，以及 v2.2.0 → v2.2.1 的真实 31 资源升级、重复安装和原版还原。安装器的 10 种异常与升级场景、中文/空格路径及目录窗口初始化检查通过。主菜单、设置菜单、提示等已进行实机检查。

尚未完整通关或逐条触发全部人物对白，部分关卡名、地名和键名仍为原文。高分辨率下仍受旧游戏位图缩放方式限制。记录见 [validation](validation)。

## 致谢

感谢 **小智2010** 从《赏金奇兵》**官方简体中文版中提取并分享的汉化补丁**。本项目以该补丁为基础适配 Steam 新版，并补充 Demo 汉化。

原补丁链接：[赏金奇兵1+2steam+gog汉化补丁（其乐 Keylol）](https://keylol.com/t100795-1-1)。思源黑体来自 Adobe Source Han Sans SC，遵循 SIL Open Font License 1.1。更多来源与许可见 [CREDITS.md](CREDITS.md)。
