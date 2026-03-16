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

## TODO

- [ ] **打破“硬编码”的后缀列表**
  - **现状**：目前应用支持的后缀名是硬编码在 `FileAssocService.swift` 的 `knownExtensions()` 中的。
  - **改进**：
    1. **动态扫描**：调用系统 API 扫描当前系统上所有已注册的文件后缀。
    2. **手动添加**：允许用户输入列表中不存在的后缀名进行查询和管理。
- [ ] **集成 Sparkle 实现自动更新**
  - [Sparkle](https://sparkle-project.org/) 是 macOS 上最流行的开源自动更新框架（VS Code、iTerm2 等均在使用）
  - **更新体验**：用户点击"安装更新" → App 自动关闭 → 替换 .app → 重新打开，无需手动拖拽 DMG
  - **实施步骤**：
    1. 通过 Swift Package Manager 添加 `https://github.com/sparkle-project/Sparkle` 依赖
    2. 在 `Info.plist` 中配置 `SUFeedURL`（指向托管的 `appcast.xml` 地址）
    3. 在 `FileOpenerApp.swift` 中初始化 `SPUStandardUpdaterController`
    4. 在工具栏或菜单中添加"检查更新"按钮，调用 `updaterController.checkForUpdates(nil)`
    5. 发布时打包 `.zip`（Sparkle 更新用）+ `.dmg`（首次安装用），上传到 GitHub Releases
    6. 维护 `appcast.xml` 描述版本号、下载地址、更新说明（可用 Sparkle 自带的 `generate_appcast` 工具自动生成）
  - **备注**：未签名的 App 也可使用 Sparkle，需关闭签名验证；有签名则更安全
- [x] **CI/CD 自动化发布**
  - 使用 GitHub Actions 自动构建 Release、生成 DMG 并发布到 GitHub Releases。
- [ ] **右键扩展助手 (Finder Extension / Quick Action)**
  - 支持在 Finder 中右键文件 -> 服务 -> 使用 FileOpener 管理关联，无缝融入系统体验。
- [ ] **更优雅的错误与提示反馈**
  - 优化 LaunchServices API 失败时的静默无响应，通过 Alert 或 Toast 及时提示用户权限不足或失败原因。

## 许可证

MIT License
