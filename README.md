# File Opener (macOS 文件关联管理器)

一个用 Swift 和 SwiftUI 编写的原生 macOS 应用程序，用于查询和修改 macOS 文件后缀的默认打开方式。

原本是基于 Electron + Vue 3 开发的，现已完全用原生技术重写，以获得更好的性能、更小的体积和更纯粹的系统集成。

## 功能特性

- 📋 **原生列表**：列出系统所有注册的文件后缀及其实际的默认打开应用。
- 🔍 **高效搜索**：支持之后缀名、UTI 类型标识或应用名称进行过滤。
- ✏️ **修改关联**：直接修改任意后缀的默认打开程序（通过 `Change` 按钮）。
- 🔄 **批量替换**：两步流式操作。先选定一个来源应用，再选定一个目标应用，一次性替换所有相关的后缀关联。
- 🌍 **界面本地化**：完整支持中文和英文，支持应用内手动切换语言。
- 💎 **原生体验**：完美的 macOS 14+ 视觉风格，支持行选中高亮。
- 📦 **精简高效**：打包体积仅 ~2.4MB（Electron 版本通常 >100MB）。
- 🖼️ **应用图标**：实时获取并展示系统的应用原版图标，而非 Emoji。

## 技术栈

- **Swift 5.9+**
- **SwiftUI** (NavigationView, Table, Sheets, FlowLayout)
- **LaunchServices API** (直接调用系统 API 修改文件关联)
- **AppKit** (用于获取应用信息与图标)
- **Localization** (支持本地化字符串与手动切换)

## 运行与构建

### 1. 使用 Xcode

```bash
# 打开项目
open FileOpener/FileOpener.xcodeproj
```

- 在 Xcode 中选择 `FileOpener` Scheme。
- 目标设备选择 `My Mac`。
- 点击 **Run (⌘R)**。
- *注：如果提示签名，请按照提示选择 "Sign to Run Locally" 即可（无需付费开发者账号）。*

### 2. 命令行构建 (.app)

```bash
cd FileOpener
xcodebuild -project FileOpener.xcodeproj \
  -scheme FileOpener \
  -configuration Release \
  -destination "platform=macOS" \
  OBJROOT="$(pwd)/build/obj" \
  SYMROOT="$(pwd)/build/sym" \
  CODE_SIGNING_ALLOWED=NO \
  build
```

构建成功后，输出的应用程序位于 `FileOpener/build/sym/Release/FileOpener.app`。

## 项目结构

```
FileOpener/
├── FileOpener.xcodeproj     # Xcode 项目定义
└── FileOpener/
    ├── FileOpenerApp.swift  # 应用生命周期
    ├── ContentView.swift    # 主界面逻辑与工具栏
    ├── FileAssocService.swift # 核心业务层 (调用 LaunchServices)
    ├── Models.swift         # 数据模型
    ├── L10n.swift           # 本地化/语言切换管理
    ├── ChangeAppSheet.swift # 修改应用弹窗
    ├── BatchReplaceSheet.swift # 批量替换逻辑
    ├── AppIcon.icns         # 应用图标文件
    ├── Assets.xcassets      # 图片资源
    ├── Info.plist           # 元信息配置
    └── *.lproj/             # 本地化字符串 (zh-Hans, en)
```

## 分支说明

- `main`: 当前主分支，存放 Swift/SwiftUI 原生代码。
- `electron`: 旧的分支，保存了原本基于 Electron + Vue 3 的实现代码，供参考。

## 许可证

MIT License
