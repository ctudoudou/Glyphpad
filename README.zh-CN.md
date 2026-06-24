# Glyphpad

[English README](README.md)

Glyphpad 是一个原生 macOS Launchpad 替代品，面向经典 Launchpad 被移除后的使用场景。它优先保留用户熟悉的全屏应用网格、搜索、文件夹、分页和拖拽整理体验，同时提供一个独立设置窗口，用于配置布局、外观、快捷键，以及后续的大模型辅助应用分类能力。

项目默认本地优先：应用发现结果、启动器布局、文件夹、设置和分类相关数据都存储在用户本机的 SQLite 数据库中。

## 截图

![Glyphpad 启动器](docs/screenshots/launcher.png)

## 功能特色

- 类 Launchpad 的全屏应用网格和虚化背景。
- 打开后默认聚焦搜索框，可直接输入过滤应用和文件夹。
- 从 macOS 标准应用目录发现原生应用。
- 支持手动拖拽排序，并持久保存布局。
- 支持文件夹：可重命名、应用归类、拖入、拖出，空文件夹会自动删除。
- 支持纵向滚动模式和横向分页模式，横向分页会按页吸附。
- 横向分页模式下有分页圆点联动。
- 可配置网格密度、行数、列数、图标大小和自动排列。
- 可设置启动器背景图片和虚化强度。
- 独立设置窗口管理布局、外观、快捷键和 API 配置。
- 支持自定义全局快捷键来显示或隐藏 Glyphpad。
- 使用 SQLite 本地保存应用、文件夹、布局和设置。
- 已提供 OpenAI 兼容 API 的配置入口，用于后续自动分类和大模型辅助分类流程。

## 环境要求

- 安装 Xcode 的 macOS。
- Swift 6 工具链。
- 系统 SQLite 库。

当前 Swift Package 的构建平台基线是 `.macOS(.v15)`；产品目标是作为 macOS 26+ 的 Launchpad 替代品。

## 构建方式

使用 Swift Package Manager 构建和测试：

```sh
swift build
swift test
```

使用 Xcode 命令行构建 app scheme：

```sh
xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build
```

生成本地 macOS app bundle：

```sh
bash scripts/build-app-bundle.sh
```

生成结果位于：

```text
dist/Glyphpad.app
```

## 使用方式

打开生成的 app：

```sh
open dist/Glyphpad.app
```

Glyphpad 以辅助应用形式运行，启动器打开时不会常驻显示 Dock 图标。

基本使用流程：

1. 启动 Glyphpad 后，全屏应用网格会立即打开。
2. 直接输入内容，通过搜索框过滤应用和文件夹。
3. 点击应用图标启动应用。
4. 点击空白处或按 `Escape` 关闭启动器。
5. 拖拽应用图标调整顺序。
6. 将一个应用拖到另一个应用上创建文件夹。
7. 将应用拖到已有文件夹上加入文件夹。
8. 打开文件夹后，可以修改名称，也可以把应用拖回顶层网格。
9. 使用 `Command + ,` 打开设置窗口，配置布局、导航、外观、API 和全局快捷键。

## 快捷键

| 快捷键 | 功能 |
| --- | --- |
| `Option + Space` | 默认全局快捷键，用于显示或隐藏 Glyphpad，可在设置中修改。 |
| `Command + ,` | Glyphpad 激活时打开设置窗口。 |
| `Escape` | 关闭启动器。 |
| `Left Arrow` | 横向分页模式下切换到上一页。 |
| `Right Arrow` | 横向分页模式下切换到下一页。 |
| `Command + Q` | 退出 Glyphpad。 |

## 设置窗口

Glyphpad 将配置能力放在独立窗口中，避免干扰全屏启动器体验：

- **Layout**：自动排列、列数、行数、图标大小、纵向滚动和横向分页。
- **Keyboard**：录制自定义全局快捷键，并可恢复默认快捷键。
- **Appearance**：选择背景图片、清除背景图片、调整虚化强度。
- **API**：本地保存 OpenAI 兼容 endpoint 和 API key，为后续分类能力提供配置基础。

## 本地数据

运行时数据保存在本机：

```text
~/Library/Application Support/Glyphpad/Glyphpad.sqlite
```

SQLite 数据库包含应用元数据、文件夹、文件夹成员、启动器布局顺序、启动器设置、分类和分类建议相关表。

## 开发流程

项目协作流程记录在 [AGENTS.md](AGENTS.md)。有明确范围的迭代会记录在 `spaces/YYYY-MM-DD-short-requirement-name/` 下，包括背景、TODO、决策和验收标准。

常用开发命令：

```sh
swift build
swift test
xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build
```

