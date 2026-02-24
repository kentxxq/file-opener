import Foundation
import UniformTypeIdentifiers
import AppKit

// MARK: - 文件关联服务（内联原 helper 逻辑）

class FileAssocService: ObservableObject {

    // MARK: - 公开方法

    /// 列出所有已知后缀的文件关联信息（在后台线程执行，返回结果）
    func list() async -> [FileAssocItem] {
        await Task.detached(priority: .userInitiated) {
            Self.buildList()
        }.value
    }

    /// 设置指定后缀的默认应用
    func set(ext: String, bundleId: String) -> SetResult {
        let safeExt = ext.filter { $0.isLetter || $0.isNumber }
        guard let uti = Self.getUTI(for: safeExt) else {
            return SetResult(success: false, error: "Unknown extension: \(ext)")
        }
        let status = LSSetDefaultRoleHandlerForContentType(uti as CFString, .all, bundleId as CFString)
        if status == noErr {
            return SetResult(success: true, error: nil)
        } else {
            return SetResult(success: false, error: "Error code: \(status)")
        }
    }

    /// 批量设置：将多个后缀的默认应用替换为目标应用
    func batchSet(extensions: [String], targetBundleId: String) -> [(ext: String, success: Bool, error: String?)] {
        extensions.map { ext in
            let r = set(ext: ext, bundleId: targetBundleId)
            return (ext: ext, success: r.success, error: r.error)
        }
    }

    // MARK: - 内部实现

    private static func buildList() -> [FileAssocItem] {
        let extensions = knownExtensions()
        var items: [FileAssocItem] = []
        for ext in extensions {
            guard let uti = getUTI(for: ext) else { continue }
            if uti.hasPrefix("dyn.") { continue }

            let defaultBundleId = getDefaultAppBundleId(for: uti)
            let allBundleIds = getAllAppBundleIds(for: uti)

            let defaultApp = defaultBundleId.map {
                AppInfo(name: getAppName(bundleId: $0), bundleId: $0)
            }

            var seen = Set<String>()
            var availableApps: [AppInfo] = []
            for bid in allBundleIds {
                let lower = bid.lowercased()
                guard !seen.contains(lower) else { continue }
                seen.insert(lower)
                availableApps.append(AppInfo(name: getAppName(bundleId: bid), bundleId: bid))
            }

            items.append(FileAssocItem(
                ext: ext,
                uti: uti,
                defaultApp: defaultApp,
                availableApps: availableApps
            ))
        }
        return items.sorted { $0.ext.lowercased() < $1.ext.lowercased() }
    }

    private static func getUTI(for ext: String) -> String? {
        if let utType = UTType(filenameExtension: ext) {
            return utType.identifier
        }
        return nil
    }

    private static func getDefaultAppBundleId(for uti: String) -> String? {
        LSCopyDefaultRoleHandlerForContentType(uti as CFString, .all)?.takeRetainedValue() as String?
    }

    private static func getAllAppBundleIds(for uti: String) -> [String] {
        guard let handlers = LSCopyAllRoleHandlersForContentType(uti as CFString, .all)?.takeRetainedValue() else {
            return []
        }
        // swiftlint:disable:next force_cast
        return handlers as! [String]
    }

    private static func getAppName(bundleId: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return FileManager.default.displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        return bundleId.components(separatedBy: ".").last ?? bundleId
    }

    private static func knownExtensions() -> [String] {
        [
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
            "ipa", "apk", "exe", "pkg", "deb",
            // 其他
            "plist"
        ]
    }
}
