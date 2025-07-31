import Cocoa
import SwiftUI

// Global instances
let globalSettingsStore = SettingsStore()
let globalFileHelper = FileHelper()

class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsStore: SettingsStore?

    func applicationWillTerminate(_ notification: Notification) {
        print("App is quitting (AppDelegate)!")
        do {
            try settingsStore?.save()
            print("Settings saved on quit!")
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

@main
struct mkepubApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // This always works—never gets a "wrong instance"
        appDelegate.settingsStore = globalSettingsStore
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(globalFileHelper)
                .environmentObject(globalSettingsStore)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Folder…") {
                    globalFileHelper.openFolderPicker()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var fileHelper: FileHelper
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        ContentView()
            .onAppear {
                fileHelper.settingsStore = settingsStore
            }
    }
}
