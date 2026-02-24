import SwiftUI

// MARK: - 批量替换弹窗（两步流程）

struct BatchReplaceSheet: View {
    let allItems: [FileAssocItem]
    let onComplete: (Int, Int) -> Void   // (successCount, failCount)
    var onDismiss: () -> Void = {}
    @EnvironmentObject private var service: FileAssocService
    @EnvironmentObject private var appLocale: AppLocale

    // 两步状态
    @State private var selectedSourceId: String? = nil
    @State private var selectedTargetId: String? = nil
    @State private var processing = false

    // 来源应用列表（按使用数量排序）
    var uniqueDefaultApps: [(app: AppInfo, count: Int)] {
        var map: [String: (app: AppInfo, count: Int)] = [:]
        for item in allItems {
            guard let da = item.defaultApp else { continue }
            if let existing = map[da.bundleId] {
                map[da.bundleId] = (app: da, count: existing.count + 1)
            } else {
                map[da.bundleId] = (app: da, count: 1)
            }
        }
        return map.values.sorted { $0.count > $1.count }
    }

    // 受影响的后缀
    var affectedItems: [FileAssocItem] {
        guard let src = selectedSourceId else { return [] }
        return allItems.filter { $0.defaultApp?.bundleId == src }
    }

    // 可选目标应用（受影响后缀下所有可用应用的并集，排除来源）
    var targetApps: [AppInfo] {
        var map: [String: AppInfo] = [:]
        for item in affectedItems {
            for app in item.availableApps {
                if app.bundleId != selectedSourceId && map[app.bundleId] == nil {
                    map[app.bundleId] = app
                }
            }
        }
        return map.values.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var sourceAppName: String {
        uniqueDefaultApps.first { $0.app.bundleId == selectedSourceId }?.app.name ?? ""
    }

    var targetAppName: String {
        targetApps.first { $0.bundleId == selectedTargetId }?.name ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            if selectedSourceId == nil {
                // 第一步：选择来源应用
                step1Header
                Divider()
                step1Body
            } else {
                // 第二步：选择目标应用
                step2Header
                Divider()
                step2Body
            }

            Divider()
            footer
        }
        .frame(width: 460, height: 500)
    }

    // MARK: - 第一步

    var step1Header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey("batch.title"))
                    .font(.headline)
                Text(LocalizedStringKey("batch.desc"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }

    var step1Body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("batch.sourceLabel"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(uniqueDefaultApps, id: \.app.bundleId) { item in
                        Button {
                            selectedSourceId = item.app.bundleId
                            selectedTargetId = nil
                        } label: {
                            HStack(spacing: 12) {
                                AppIconView(bundleId: item.app.bundleId)
                                    .frame(width: 32, height: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.app.name).font(.body)
                                    Text(item.app.bundleId).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(String(format: appLocale.s("batch.extCount"), item.count))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - 第二步

    var step2Header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    selectedSourceId = nil
                    selectedTargetId = nil
                } label: {
                    Label(LocalizedStringKey("batch.back"), systemImage: "chevron.left")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)

                Spacer()
            }

            // 来源 → 目标 指示
            HStack(spacing: 8) {
                AppIconView(bundleId: selectedSourceId ?? "")
                    .frame(width: 24, height: 24)
                Text(sourceAppName).fontWeight(.medium)
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                if let tid = selectedTargetId {
                    AppIconView(bundleId: tid)
                        .frame(width: 24, height: 24)
                    Text(targetAppName).fontWeight(.medium)
                } else {
                    Text("?").foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)

            // 受影响后缀标签
            ExtTagsView(items: affectedItems)
        }
        .padding()
    }

    var step2Body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("batch.targetLabel"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)

            if targetApps.isEmpty {
                HStack {
                    Spacer()
                    Text(LocalizedStringKey("batch.noApps"))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(targetApps) { app in
                            AppOptionRow(
                                app: app,
                                isCurrent: selectedTargetId == app.bundleId
                            ) {
                                selectedTargetId = app.bundleId
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    // MARK: - 底部按钮

    var footer: some View {
        HStack {
            Button(LocalizedStringKey("btn.close")) { onDismiss() }
                .keyboardShortcut(.escape)

            Spacer()

            if selectedSourceId != nil, let targetId = selectedTargetId {
                Button {
                    executeBatch(targetBundleId: targetId)
                } label: {
                    if processing {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.7)
                        Text(LocalizedStringKey("batch.processing"))
                    } else {
                        Text("\(appLocale.s("btn.batchConfirm")) (\(affectedItems.count))")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(processing)
            }
        }
        .padding()
    }

    // MARK: - 执行批量替换

    @MainActor
    private func executeBatch(targetBundleId: String) {
        processing = true
        let exts = affectedItems.map { $0.ext }
        let results = service.batchSet(extensions: exts, targetBundleId: targetBundleId)
        let successCount = results.filter { $0.success }.count
        let failCount = results.count - successCount
        onComplete(successCount, failCount)
    }
}

// MARK: - 后缀标签组件

struct ExtTagsView: View {
    let items: [FileAssocItem]

    private let extColors: [String: Color] = [
        "txt": .indigo, "html": .indigo, "css": .indigo,
        "js": .yellow, "ts": .blue, "json": .yellow,
        "py": .orange, "swift": .orange, "go": .cyan,
        "pdf": .red, "doc": .blue, "docx": .blue,
        "xls": .green, "xlsx": .green,
        "jpg": .pink, "jpeg": .pink, "png": .purple, "gif": .pink,
        "mp3": .cyan, "wav": .cyan, "mp4": .purple, "mkv": .purple,
        "zip": .yellow, "rar": .yellow, "dmg": .gray
    ]

    var body: some View {
        if items.isEmpty { EmptyView() } else {
            FlowLayout(spacing: 4) {
                ForEach(items) { item in
                    Text(".\(item.ext)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((extColors[item.ext] ?? .gray).opacity(0.15))
                        .foregroundStyle(extColors[item.ext] ?? .secondary)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - FlowLayout（标签流式布局）

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += lineHeight + spacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxHeight = max(maxHeight, y + lineHeight)
        }
        return CGSize(width: width, height: maxHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += lineHeight + spacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
