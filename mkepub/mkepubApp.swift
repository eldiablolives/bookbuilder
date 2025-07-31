import SwiftUI

@main
struct mkepubApp: App {
    @StateObject private var fileHelper = FileHelper()
    @StateObject private var settingsStore = SettingsStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fileHelper)
                .environmentObject(settingsStore)
                .onAppear {
                    fileHelper.settingsStore = settingsStore
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Folder…") {
                    fileHelper.openFolderPicker()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}
