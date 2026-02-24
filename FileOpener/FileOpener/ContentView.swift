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
            toastOverlay
        }
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

    // MARK: - Toast 覆盖层（独立动画作用域）

    @ViewBuilder
    var toastOverlay: some View {
        if let toast {
            ToastView(data: toast)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: toast.id)
        }
    }

    // MARK: - 工具栏（固定尺寸，避免语言切换或刷新时布局跳动）

    var toolbar: some View {
        HStack(spacing: 12) {
            // ── 左侧：搜索框 + 统计 ──
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(LocalizedStringKey("search.placeholder"), text: $searchQuery)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 180)
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

            Text("\(filteredItems.count) / \(allItems.count) \(appLocale.s("stat.suffix"))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize()

            Spacer()

            // ── 右侧：操作按钮组 ──
            HStack(spacing: 8) {
                // 批量替换
                Button {
                    showBatchSheet = true
                } label: {
                    Label(appLocale.s("btn.batchReplace"), systemImage: "arrow.2.squarepath")
                        .fixedSize()
                }

                // 刷新（旋转图标指示加载中，和批量替换按钮结构一致）
                Button {
                    Task { await refresh() }
                } label: {
                    Label {
                        Text(appLocale.s("btn.refresh"))
                    } icon: {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(refreshing ? 360 : 0))
                            .animation(refreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: refreshing)
                    }
                    .fixedSize()
                }
                .disabled(refreshing)
            }
            .controlSize(.regular)
            .buttonStyle(.bordered)

            // ── 分隔符 ──
            Divider()
                .frame(height: 20)

            // ── 设置区域：语言切换 ──
            Button(action: { appLocale.toggle() }) {
                Image(systemName: "globe")
                    .imageScale(.medium)
                Text(appLocale.switchLabel)
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help("切换语言 / Switch Language")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 表格（带行选中 + 固定列宽）

    // 各列宽度比例：后缀 10%, UTI 25%, 默认应用 35%, 可选数 12%, 操作 18%
    private let colRatios: [CGFloat] = [0.10, 0.25, 0.35, 0.12, 0.18]

    var tableView: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let widths = colRatios.map { $0 * totalWidth }

            VStack(spacing: 0) {
                // 表头
                HStack(spacing: 0) {
                    headerCell(appLocale.s("table.ext"), width: widths[0])
                    headerCell(appLocale.s("table.uti"), width: widths[1])
                    headerCell(appLocale.s("table.defaultApp"), width: widths[2])
                    headerCell(appLocale.s("table.availableCount"), width: widths[3], alignment: .center)
                    headerCell(appLocale.s("table.action"), width: widths[4], alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.04))

                Divider()

                // 数据行
                List(filteredItems, selection: $selectedIds) { item in
                    HStack(spacing: 0) {
                        ExtBadgeView(ext: item.ext)
                            .frame(width: widths[0], alignment: .leading)

                        Text(item.uti)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .help(item.uti)
                            .frame(width: widths[1], alignment: .leading)

                        Group {
                            if let app = item.defaultApp {
                                HStack(spacing: 6) {
                                    AppIconView(bundleId: app.bundleId)
                                        .frame(width: 18, height: 18)
                                    Text(app.name)
                                        .lineLimit(1)
                                }
                            } else {
                                Text(appLocale.s("table.notSet"))
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }
                        }
                        .frame(width: widths[2], alignment: .leading)

                        Text("\(item.availableApps.count)")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .frame(width: widths[3], alignment: .center)

                        Button {
                            selectedItem = item
                        } label: {
                            Text(appLocale.s("btn.change"))
                                .frame(minWidth: 40)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(item.availableApps.isEmpty ? .gray : .blue)
                        .controlSize(.small)
                        .disabled(item.availableApps.isEmpty)
                        .frame(width: widths[4], alignment: .center)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(.plain)
            }
        }
    }

    private func headerCell(_ title: String, width: CGFloat, alignment: Alignment = .leading) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: alignment)
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
            withAnimation(.easeInOut(duration: 0.2)) {
                toast = nil
            }
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

struct ToastData: Identifiable, Equatable {
    enum ToastType { case success, error }
    let id = UUID()
    let message: String
    let type: ToastType

    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        lhs.id == rhs.id
    }
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
