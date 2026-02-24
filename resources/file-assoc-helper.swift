import Foundation
import UniformTypeIdentifiers
import AppKit

// MARK: - 数据模型

struct AppInfo: Codable {
    let name: String
    let bundleId: String
}

struct FileAssocItem: Codable {
    let ext: String
    let uti: String
    let defaultApp: AppInfo?
    let availableApps: [AppInfo]
}

struct SetResult: Codable {
    let success: Bool
    let error: String?
}

// MARK: - 工具函数

/// 通过 bundleId 获取应用名称
func getAppName(bundleId: String) -> String {
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
        return FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
    }
    // 取 bundleId 最后一段作为名称
    return bundleId.components(separatedBy: ".").last ?? bundleId
}

/// 获取指定 UTI 的默认应用 bundleId
func getDefaultAppBundleId(for uti: String) -> String? {
    // 使用 LSCopyDefaultRoleHandlerForContentType (macOS 12+)
    if let handler = LSCopyDefaultRoleHandlerForContentType(uti as CFString, .all)?.takeRetainedValue() {
        return handler as String
    }
    return nil
}

/// 获取指定 UTI 的所有可用应用 bundleId
func getAllAppBundleIds(for uti: String) -> [String] {
    if let handlers = LSCopyAllRoleHandlersForContentType(uti as CFString, .all)?.takeRetainedValue() {
        return handlers as! [String]
    }
    return []
}

/// 通过文件后缀获取 UTI 字符串
func getUTI(for ext: String) -> String? {
    if #available(macOS 11.0, *) {
        if let utType = UTType(filenameExtension: ext) {
            return utType.identifier
        }
    }
    // 回退到旧 API
    if let utiRef = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension, ext as CFString, nil
    )?.takeRetainedValue() {
        return utiRef as String
    }
    return nil
}

/// 收集系统中已知的常见文件后缀列表
func collectKnownExtensions() -> [String] {
    // 常见文件后缀列表，覆盖代码/文档/媒体/压缩等
    let extensions = [
        // 文本/代码
        "txt", "html", "htm", "css", "js", "ts", "jsx", "tsx",
        "json", "xml", "yaml", "yml", "toml", "ini", "cfg", "conf",
        "log", "md", "markdown", "csv", "tsv",
        // 编程语言
        "py", "rb", "java", "c", "cpp", "h", "hpp", "m", "mm",
        "swift", "go", "rs", "sh", "bash", "zsh", "bat", "ps1",
        "php", "pl", "r", "lua", "scala", "kt", "dart", "vue",
        // 数据库
        "sql", "db", "sqlite", "sqlite3",
        // 文档
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
        "rtf", "odt", "ods", "odp", "pages", "numbers", "key",
        // 图片
        "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif",
        "svg", "webp", "ico", "heic", "heif", "raw", "psd", "ai",
        // 音频
        "mp3", "wav", "flac", "aac", "ogg", "wma", "m4a", "aiff", "alac",
        // 视频
        "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v",
        "mpg", "mpeg", "3gp",
        // 压缩包
        "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "iso",
        // 设计
        "sketch", "fig", "xd",
        // 字体
        "ttf", "otf", "woff", "woff2",
        // 可执行/包
        "ipa", "apk", "exe", "app", "pkg", "deb", "rpm", "msi",
        // 其他
        "plist", "cer", "p12", "mobileprovision",
        "dockerfile", "makefile", "gitignore",
    ]
    return extensions
}

// MARK: - 命令处理

/// list 命令：列出所有已知后缀的文件关联信息
func handleList() {
    let extensions = collectKnownExtensions()
    var items: [FileAssocItem] = []

    for ext in extensions {
        guard let uti = getUTI(for: ext) else { continue }

        // 跳过动态 UTI（dyn. 开头，表示系统不认识的类型）
        if uti.hasPrefix("dyn.") { continue }

        let defaultBundleId = getDefaultAppBundleId(for: uti)
        let allBundleIds = getAllAppBundleIds(for: uti)

        let defaultApp: AppInfo? = defaultBundleId.map {
            AppInfo(name: getAppName(bundleId: $0), bundleId: $0)
        }

        // 去重并构建可用应用列表
        var seen = Set<String>()
        var availableApps: [AppInfo] = []
        for bundleId in allBundleIds {
            let lower = bundleId.lowercased()
            if seen.contains(lower) { continue }
            seen.insert(lower)
            availableApps.append(AppInfo(name: getAppName(bundleId: bundleId), bundleId: bundleId))
        }

        items.append(FileAssocItem(
            ext: ext,
            uti: uti,
            defaultApp: defaultApp,
            availableApps: availableApps
        ))
    }

    // 按后缀名排序
    items.sort { $0.ext.lowercased() < $1.ext.lowercased() }

    let encoder = JSONEncoder()
    if let data = try? encoder.encode(items),
       let json = String(data: data, encoding: .utf8) {
        print(json)
    } else {
        print("[]")
    }
}

/// query 命令：查询指定后缀的详细信息
func handleQuery(ext: String) {
    guard let uti = getUTI(for: ext) else {
        print("null")
        return
    }

    let defaultBundleId = getDefaultAppBundleId(for: uti)
    let allBundleIds = getAllAppBundleIds(for: uti)

    let defaultApp: AppInfo? = defaultBundleId.map {
        AppInfo(name: getAppName(bundleId: $0), bundleId: $0)
    }

    var seen = Set<String>()
    var availableApps: [AppInfo] = []
    for bundleId in allBundleIds {
        let lower = bundleId.lowercased()
        if seen.contains(lower) { continue }
        seen.insert(lower)
        availableApps.append(AppInfo(name: getAppName(bundleId: bundleId), bundleId: bundleId))
    }

    let item = FileAssocItem(
        ext: ext,
        uti: uti,
        defaultApp: defaultApp,
        availableApps: availableApps
    )

    let encoder = JSONEncoder()
    if let data = try? encoder.encode(item),
       let json = String(data: data, encoding: .utf8) {
        print(json)
    } else {
        print("null")
    }
}

/// set 命令：设置指定后缀的默认应用
func handleSet(ext: String, bundleId: String) {
    guard let uti = getUTI(for: ext) else {
        let result = SetResult(success: false, error: "Unknown extension: \(ext)")
        outputSetResult(result)
        return
    }

    let status = LSSetDefaultRoleHandlerForContentType(uti as CFString, .all, bundleId as CFString)

    if status == noErr {
        let result = SetResult(success: true, error: nil)
        outputSetResult(result)
    } else {
        let result = SetResult(success: false, error: "LSSetDefaultRoleHandlerForContentType failed with status: \(status)")
        outputSetResult(result)
    }
}

func outputSetResult(_ result: SetResult) {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(result),
       let json = String(data: data, encoding: .utf8) {
        print(json)
    } else {
        print("{\"success\":false,\"error\":\"JSON encoding failed\"}")
    }
}

// MARK: - 主入口

let args = CommandLine.arguments

guard args.count >= 2 else {
    fputs("Usage: file-assoc-helper <list|query|set> [args...]\n", stderr)
    exit(1)
}

let command = args[1]

switch command {
case "list":
    handleList()
case "query":
    guard args.count >= 3 else {
        fputs("Usage: file-assoc-helper query <ext>\n", stderr)
        exit(1)
    }
    handleQuery(ext: args[2])
case "set":
    guard args.count >= 4 else {
        fputs("Usage: file-assoc-helper set <ext> <bundleId>\n", stderr)
        exit(1)
    }
    handleSet(ext: args[2], bundleId: args[3])
default:
    fputs("Unknown command: \(command)\n", stderr)
    exit(1)
}
