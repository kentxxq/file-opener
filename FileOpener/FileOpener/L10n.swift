import SwiftUI

// MARK: - i18n 支持

struct L10n {
    // 根据系统语言决定语言，支持手动切换
    static func string(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        if args.isEmpty { return format }
        return String(format: format, arguments: args)
    }
}
