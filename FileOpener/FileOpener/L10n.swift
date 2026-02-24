import Foundation
import SwiftUI

// MARK: - 应用语言管理（支持手动切换中英文）

class AppLocale: ObservableObject {

    @AppStorage("appLang") var lang: String = "auto" {
        didSet { updateBundle() }
    }

    private var localizedBundle: Bundle = Bundle.main

    init() { updateBundle() }

    /// SwiftUI .environment(\.locale, ...) 使用的 Locale
    var locale: Locale {
        switch lang {
        case "zh-Hans": return Locale(identifier: "zh-Hans")
        case "en":      return Locale(identifier: "en")
        default:        return .autoupdatingCurrent
        }
    }

    /// 工具栏语言切换按钮的标签
    var switchLabel: String {
        switch lang {
        case "zh-Hans": return "EN"
        case "en":      return "中"
        default:
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            return code.hasPrefix("zh") ? "EN" : "中"
        }
    }

    /// 切换语言
    func toggle() {
        switch lang {
        case "zh-Hans": lang = "en"
        case "en":      lang = "zh-Hans"
        default:
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            lang = code.hasPrefix("zh") ? "en" : "zh-Hans"
        }
    }

    /// 获取本地化字符串（支持 printf 格式参数）
    func s(_ key: String, _ args: CVarArg...) -> String {
        let format = localizedBundle.localizedString(forKey: key, value: key, table: nil)
        if args.isEmpty { return format }
        return String(format: format, arguments: args)
    }

    private func updateBundle() {
        let lprojName: String
        switch lang {
        case "zh-Hans": lprojName = "zh-Hans"
        case "en":      lprojName = "en"
        default:
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            lprojName = code.hasPrefix("zh") ? "zh-Hans" : "en"
        }
        if let path = Bundle.main.path(forResource: lprojName, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            localizedBundle = bundle
        } else {
            localizedBundle = Bundle.main
        }
    }
}
