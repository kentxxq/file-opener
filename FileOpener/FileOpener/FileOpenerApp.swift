import SwiftUI

@main
struct FileOpenerApp: App {
    @StateObject private var service = FileAssocService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(service)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 960, height: 680)
        .commands {
            // 移除默认的 New Window 等不需要的菜单项
            CommandGroup(replacing: .newItem) {}
        }
    }
}
