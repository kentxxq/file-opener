import SwiftUI
import Cocoa

class AppState {
    static var pendingExtension: String? = nil
}

class ServiceProvider: NSObject {
    @objc func handleManageAssociation(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let items = pboard.pasteboardItems else { return }
        
        for item in items {
            if let stringString = item.string(forType: .fileURL), let url = URL(string: stringString) {
                let ext = url.pathExtension
                if !ext.isEmpty {
                    DispatchQueue.main.async {
                        AppState.pendingExtension = ext
                        
                        NSApp.setActivationPolicy(.regular)
                        NSApp.activate(ignoringOtherApps: true)
                        
                        let hasWindows = NSApp.windows.contains { $0.canBecomeKey }
                        if !hasWindows {
                            let config = NSWorkspace.OpenConfiguration()
                            config.createsNewApplicationInstance = false
                            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: Bundle.main.bundlePath), configuration: config, completionHandler: nil)
                        } else {
                            NSApp.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
                        }
                        
                        NotificationCenter.default.post(name: NSNotification.Name("ManageExtension"), object: ext)
                    }
                    break
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let serviceProvider = ServiceProvider()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
    }
}

@main
struct FileOpenerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
