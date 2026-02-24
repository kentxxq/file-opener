# file-assoc-manager

macOS 文件关联管理器 — 查询与修改 macOS 文件后缀的默认打开方式。

## 功能特性

- 📋 列出系统所有注册的文件后缀及其默认打开应用
- 🔍 搜索过滤（支持后缀名、UTI 类型标识、应用名）
- ✏️ 修改任意后缀的默认打开应用
- 🌍 中英文界面切换
- 🎨 深色主题，macOS 原生风格

## 技术栈

- **Electron** - 桌面应用框架
- **Vue 3** - 前端 UI 框架
- **TypeScript** - 开发语言
- **electron-vite** - 构建工具

## 开发

```bash
# 安装依赖
npm install

# 开发模式运行
npm run dev

# 构建
npm run build

# 打包 DMG
npm run package
```

## 项目结构

```
src/
├── main/           # Electron 主进程
│   └── index.ts
├── preload/        # 预加载脚本
│   └── index.ts
└── renderer/       # 渲染进程 (Vue)
    ├── App.vue     # 根组件
    ├── main.ts     # 入口
    ├── i18n.ts     # 国际化
    ├── types.ts    # 类型定义
    ├── env.d.ts    # 类型声明
    └── assets/
        └── main.css
```
