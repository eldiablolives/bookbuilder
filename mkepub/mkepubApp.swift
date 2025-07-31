import SwiftUI

@main
struct mkepubApp: App {
    @StateObject private var fileHelper = FileHelper()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fileHelper)
        }
        .commands {
            CommandGroup(after: .newItem) { // Places "Open Folder…" after "New..."
                Button("Open Folder…") {
                    fileHelper.openFolderPicker()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}
