import SwiftUI
import UniformTypeIdentifiers

struct CentralPanelView: View {
    @ObservedObject var fileHelper: FileHelper
    @Binding var selectedTab: String
    @EnvironmentObject var settingsStore: SettingsStore

    // The selected file indicating where the book begins
    @State private var startingFile: URL?

    // Currently dragged item (for reordering)
    @State private var draggedItem: URL?

    var body: some View {
        VStack {
            header
            topFields
            fileListSection
        }
        .background(Color.gray.opacity(0.1))
        .onAppear {
            restoreStartingFileFromSettings()
            syncFilesIntoSettings()
        }
        .onChange(of: fileHelper.selectedFiles) {
            restoreStartingFileFromSettings()
            syncFilesIntoSettings()
        }
        .onChange(of: startingFile) { oldFile, newFile in
            if let file = newFile {
                settingsStore.settings.start = file.lastPathComponent
            } else {
                settingsStore.settings.start = nil
            }
            saveSettings()
        }
    }
}

// MARK: - Header
private extension CentralPanelView {
    var header: some View {
        Text("Processor")
            .font(.headline)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal)
    }
}

// MARK: - Top fields
private extension CentralPanelView {
    var topFields: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                TextField(
                    "Book Title",
                    text: Binding(
                        get: { settingsStore.settings.title ?? "" },
                        set: { settingsStore.settings.title = $0 }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 8)

                TextField(
                    "Author",
                    text: Binding(
                        get: { settingsStore.settings.author ?? "" },
                        set: { settingsStore.settings.author = $0 }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 8)
            }
            .padding()
            .border(Color.gray.opacity(0.5), width: 1)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - File list
private extension CentralPanelView {
    var fileListSection: some View {
        VStack {
            Text("[\(fileHelper.selectedFiles.count)] Selected files, (\(settingsStore.settings.words ?? 0) words)")
                .font(.headline)

            List {
                ForEach(fileHelper.selectedFiles, id: \.self) { file in
                    fileRow(for: file)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    func fileRow(for file: URL) -> some View {
        HStack {
            // Radio button
            Image(systemName: startingFile == file ? "largecircle.fill.circle" : "circle")
                .foregroundColor(.blue)

            Text(file.lastPathComponent)
                .lineLimit(1)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            startingFile = file
        }
        .onDrag {
            draggedItem = file
            return NSItemProvider(object: file.lastPathComponent as NSString)
        }
        .onDrop(
            of: [UTType.text],
            delegate: FileDropDelegate(
                item: file,
                items: $fileHelper.selectedFiles,
                draggedItem: $draggedItem
            )
        )
    }
}

// MARK: - Sync helpers
private extension CentralPanelView {
    /// Sync selectedFiles → settings.files
    func syncFilesIntoSettings() {
        settingsStore.settings.files = fileHelper.selectedFiles.map { $0.lastPathComponent }
        saveSettings()
    }

    func saveSettings() {
        do {
            try settingsStore.save()
            print("Settings saved from CentralPanelView")
        } catch {
            print("Failed to save settings from CentralPanelView: \(error)")
        }
    }

    /// Restore startingFile from settings.start (filename)
    func restoreStartingFileFromSettings() {
        guard !fileHelper.selectedFiles.isEmpty else {
            startingFile = nil
            return
        }

        let savedStartName = settingsStore.settings.start

        // Try to find file by name
        if let savedName = savedStartName,
           let matchingFile = fileHelper.selectedFiles.first(where: { $0.lastPathComponent == savedName }) {
            startingFile = matchingFile
        } else {
            // Default to first file
            startingFile = fileHelper.selectedFiles.first
            // Save the default
            settingsStore.settings.start = startingFile?.lastPathComponent
            saveSettings()
        }
    }
}

// MARK: - Drop delegate
struct FileDropDelegate: DropDelegate {
    let item: URL
    @Binding var items: [URL]
    @Binding var draggedItem: URL?

    func dropEntered(info: DropInfo) {}

    func performDrop(info: DropInfo) -> Bool {
        guard
            let dragged = draggedItem,
            dragged != item,
            let fromIndex = items.firstIndex(of: dragged),
            let toIndex = items.firstIndex(of: item)
        else {
            draggedItem = nil
            return false
        }

        withAnimation {
            items.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }

        draggedItem = nil
        return true
    }
}
