import SwiftUI

@main
struct FileOpenerApp: App {
    @StateObject private var service = FileAssocService()
    @StateObject private var appLocale = AppLocale()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(service)
                .environmentObject(appLocale)
                .environment(\.locale, appLocale.locale)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 960, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
