import SwiftUI

// MARK: - 主视图

struct ContentView: View {
    @EnvironmentObject private var service: FileAssocService
    @EnvironmentObject private var appLocale: AppLocale

    @State private var allItems: [FileAssocItem] = []
    @State private var searchQuery: String = ""
    @State private var loading = true
    @State private var refreshing = false
    @State private var toast: ToastData? = nil
    @State private var selectedIds: Set<String> = []

    // 弹窗状态
    @State private var selectedItem: FileAssocItem? = nil
    @State private var showBatchSheet = false

    // 过滤后列表
    var filteredItems: [FileAssocItem] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return allItems }
        return allItems.filter {
            $0.ext.lowercased().contains(q) ||
            $0.uti.lowercased().contains(q) ||
            ($0.defaultApp?.name.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            if loading {
                loadingView
            } else if filteredItems.isEmpty {
                emptyView
            } else {
                tableView
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .overlay(alignment: .bottom) {
            if let toast {
                ToastView(data: toast)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast?.id)
        .task { await loadData() }
        .sheet(item: $selectedItem) { item in
            ChangeAppSheet(item: item) { app in
                applyChange(ext: item.ext, app: app)
            }
        }
        .sheet(isPresented: $showBatchSheet) {
            BatchReplaceSheet(allItems: allItems) { success, fail in
                showToast(appLocale.s("toast.batchSuccess", success, fail),
                          type: fail == 0 ? .success : .error)
                Task { await loadData() }
            }
            .environmentObject(service)
            .environmentObject(appLocale)
        }
    }

    // MARK: - 工具栏

    var toolbar: some View {
        HStack(spacing: 10) {
            // 搜索框
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(LocalizedStringKey("search.placeholder"), text: $searchQuery)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 200)
                if !searchQuery.isEmpty {
                    Button { searchQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 统计
            Text("\(filteredItems.count) / \(allItems.count) \(appLocale.s("stat.suffix"))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // 语言切换
            Button(action: {
                appLocale.toggle()
            }) {
                Text(appLocale.switchLabel)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28)
            }
            .buttonStyle(.bordered)
            .help("切换语言 / Switch Language")

            // 批量替换
            Button {
                showBatchSheet = true
            } label: {
                Label(LocalizedStringKey("btn.batchReplace"), systemImage: "arrow.2.squarepath")
            }
            .buttonStyle(.bordered)

            // 刷新
            Button {
                Task { await refresh() }
            } label: {
                if refreshing {
                    ProgressView().progressViewStyle(.circular).scaleEffect(0.7)
                } else {
                    Label(LocalizedStringKey("btn.refresh"), systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(.bordered)
            .disabled(refreshing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 表格（带行选中）

    var tableView: some View {
        Table(filteredItems, selection: $selectedIds) {
            TableColumn(LocalizedStringKey("table.ext")) { item in
                ExtBadgeView(ext: item.ext)
            }
            .width(min: 80, ideal: 90)

            TableColumn(LocalizedStringKey("table.uti")) { item in
                Text(item.uti)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help(item.uti)
            }
            .width(min: 180, ideal: 240)

            TableColumn(LocalizedStringKey("table.defaultApp")) { item in
                if let app = item.defaultApp {
                    HStack(spacing: 6) {
                        AppIconView(bundleId: app.bundleId)
                            .frame(width: 18, height: 18)
                        Text(app.name)
                            .lineLimit(1)
                    }
                } else {
                    Text(LocalizedStringKey("table.notSet"))
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }

            TableColumn(LocalizedStringKey("table.availableCount")) { item in
                Text("\(item.availableApps.count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .width(60)

            TableColumn(LocalizedStringKey("table.action")) { item in
                Button {
                    selectedItem = item
                } label: {
                    Text(LocalizedStringKey("btn.change"))
                        .frame(minWidth: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(item.availableApps.isEmpty ? .gray : .blue)
                .controlSize(.small)
                .disabled(item.availableApps.isEmpty)
            }
            .width(70)
        }
    }

    // MARK: - 加载 / 空状态

    var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(LocalizedStringKey("loading.text"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey("empty.text"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 数据操作

    func loadData() async {
        let data = await service.list()
        await MainActor.run {
            allItems = data
            loading = false
        }
    }

    func refresh() async {
        refreshing = true
        await loadData()
        refreshing = false
        showToast(appLocale.s("toast.refreshed"), type: .success)
    }

    func applyChange(ext: String, app: AppInfo) {
        let result = service.set(ext: ext.filter { $0.isLetter || $0.isNumber }, bundleId: app.bundleId)
        if result.success {
            if let idx = allItems.firstIndex(where: { $0.ext == ext }) {
                allItems[idx] = FileAssocItem(
                    ext: allItems[idx].ext,
                    uti: allItems[idx].uti,
                    defaultApp: app,
                    availableApps: allItems[idx].availableApps
                )
            }
            showToast(appLocale.s("toast.setSuccess", ext, app.name), type: .success)
        } else {
            showToast(appLocale.s("toast.setFailed", result.error ?? ""), type: .error)
        }
    }

    // MARK: - Toast

    func showToast(_ message: String, type: ToastData.ToastType) {
        toast = ToastData(message: message, type: type)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            toast = nil
        }
    }
}

// MARK: - 后缀徽章

struct ExtBadgeView: View {
    let ext: String

    static let colors: [String: Color] = [
        "txt": .indigo, "html": .indigo, "css": .indigo,
        "js": .yellow, "ts": .blue, "json": .yellow,
        "py": .orange, "swift": .orange, "go": .cyan, "rs": .orange,
        "pdf": .red, "doc": .blue, "docx": .blue,
        "xls": .green, "xlsx": .green,
        "jpg": .pink, "jpeg": .pink, "png": .purple, "gif": .pink,
        "svg": .yellow, "heic": .pink,
        "mp3": .cyan, "wav": .cyan, "flac": .teal, "m4a": .cyan,
        "mp4": .purple, "mkv": .purple, "mov": .purple, "avi": .purple,
        "zip": .orange, "rar": .orange, "7z": .orange, "dmg": .gray,
        "plist": .gray
    ]

    var color: Color { Self.colors[ext] ?? .gray }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(".\(ext)")
                .font(.system(.body, design: .monospaced))
        }
    }
}

// MARK: - Toast 数据 & 视图

struct ToastData: Identifiable {
    enum ToastType { case success, error }
    let id = UUID()
    let message: String
    let type: ToastType
}

struct ToastView: View {
    let data: ToastData

    var bg: Color { data.type == .success ? .green : .red }
    var icon: String { data.type == .success ? "checkmark.circle.fill" : "xmark.circle.fill" }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(data.message)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(bg.opacity(0.9))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 8)
    }
}
