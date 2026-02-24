import SwiftUI

// MARK: - 修改默认应用弹窗

struct ChangeAppSheet: View {
    let item: FileAssocItem
    let onSelect: (AppInfo) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(LocalizedStringKey("modal.title"))
                            .font(.headline)
                        Text(".\(item.ext)")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                        Text(LocalizedStringKey("modal.titleSuffix"))
                            .font(.headline)
                    }
                    Text("UTI: \(item.uti)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { onClose() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // 应用列表
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(item.availableApps) { app in
                        AppOptionRow(
                            app: app,
                            isCurrent: item.defaultApp?.bundleId == app.bundleId
                        ) {
                            onSelect(app)
                            onClose()
                        }
                    }
                }
                .padding()
            }

            Divider()

            // 底部
            HStack {
                Spacer()
                Button(LocalizedStringKey("btn.close")) { onClose() }
                    .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 420, height: 440)
    }
}

// MARK: - 应用选项行（复用）

struct AppOptionRow: View {
    let app: AppInfo
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 应用图标（从系统获取，fallback 用方块）
                AppIconView(bundleId: app.bundleId)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(app.bundleId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isCurrent {
                    Text(LocalizedStringKey("modal.currentTag"))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isCurrent ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isCurrent ? Color.accentColor.opacity(0.4) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 应用图标视图

struct AppIconView: View {
    let bundleId: String

    var icon: NSImage? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }

    var body: some View {
        if let nsImage = icon {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "app.dashed")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
