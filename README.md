# Desperados - Wanted Dead or Alive 中文汉化修复

《赏金奇兵：西部通缉令》Steam 新版汉化补丁，合并主游戏和 Demo，支持选择游戏路径、自动备份及一键恢复。

## 下载

在 [Releases](https://github.com/newbility/Desperados_Wanted_Dead_or_Alive_Chinese/releases/latest) 下载 **Desperados_Chinese_Main_and_Demo_v2.1.0.zip** 并完整解压。仓库中的安装脚本供查看和维护，实际安装请使用 Release 中包含资源文件的完整压缩包。

适用 Steam Build **2959430**，主程序为 `desperados.exe`。

## 安装与使用

1. 关闭游戏，双击解压文件夹内的 **Install.cmd**。
2. 在窗口中选择**包含 desperados.exe 的游戏根目录**，点击“确定”。支持其他盘符、中文和空格路径。
3. 安装器校验版本、备份原资源，并安装主游戏和 Demo 汉化。
4. 正常从 Steam 启动：**下方 Wanted Dead or Alive 区域的英美旗帜**进入主游戏，**上方 Demo Mission 区域的英美旗帜**进入 Demo。

需要撤销时，先关闭游戏，再运行同一文件夹中的 **Restore.cmd**。它会使用安装时记录的路径，同时还原主游戏和 Demo。请保留 `backups` 文件夹和 `installation.json`。

完整说明见 [使用说明](installer/使用说明.md)。

## 汉化内容

- 主游戏 1086 条对白、任务说明及提示，139 条菜单及状态文字。
- 13 套中文字库，保留原有拉丁字符。
- 汉化主菜单背景与两张任务结算画面。
- 12 段过场视频、117 条中文字幕，保留原音轨。
- Demo 的 139 条菜单文字、6 页中文操作指南，复用 49 条中文对白及任务提示。

合并包共 31 个资源文件，不替换游戏主程序或存档。

## 验证情况

主游戏和 Demo 中文菜单已实测，6 页教程经过逐页检查。资源、字形覆盖、视频格式与时间轴、原音轨均已校验；安装器已检查首次安装、旧包升级、重复运行、异常回滚和统一恢复。未完整通关、逐条触发所有对白，部分关卡名、地图地名和键名仍保留原文。

校验记录见 [validation](validation)。

## 致谢

感谢 **小智2010** 从《赏金奇兵》**官方简体中文版中提取并分享的汉化补丁**。本项目以该补丁为基础，适配 Steam 新版，并补充 Demo 的中文菜单和操作指南。

原补丁链接：[赏金奇兵1+2steam+gog汉化补丁（其乐 Keylol）](https://keylol.com/t100795-1-1)。更多来源说明见 [CREDITS.md](CREDITS.md)。
