import Foundation

// MARK: - 数据模型

struct AppInfo: Identifiable, Hashable {
    var id: String { bundleId }
    let name: String
    let bundleId: String
}

struct FileAssocItem: Identifiable {
    var id: String { ext }
    let ext: String
    let uti: String
    var defaultApp: AppInfo?
    let availableApps: [AppInfo]
    let isCustom: Bool
}

struct SetResult {
    let success: Bool
    let error: String?
}
