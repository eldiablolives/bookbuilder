import SwiftUI

struct EBookTabView: View {
    @ObservedObject var fileHelper: FileHelper
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        VStack {
            // ────── Cover ──────
            Group {
                if let image = fileHelper.coverImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(Text("Click to Select Cover Image")
                            .foregroundColor(.gray))
                }
            }
            .frame(width: 100, height: 150)
            .onTapGesture { fileHelper.openImagePicker() }
            .padding(.bottom, 8)

            // ────── Style ──────
            Button("Select Style") { fileHelper.openStylePicker() }

            if let styleFile = fileHelper.selectedStyleFile {
                Text("Selected style: \(styleFile.lastPathComponent)")
                    .font(.caption)
                    .padding(.top, 4)
            }

            // ────── Fonts ──────
            Text("Added Fonts:")
                .font(.headline)
                .padding(.top, 8)

            List(fileHelper.addedFonts, id: \.self) { font in
                Text(font.lastPathComponent)
            }
            .frame(height: 100)

            Button("Add Font") { fileHelper.openFontPicker() }
                .padding(.top, 8)

            // ────── Build ──────
            Button(action: {
                // ensure the latest values are on disk before building
                syncEbookSettingsFromFileHelper()
                fileHelper.selectedBookType = .eBook
                fileHelper.selectDestinationFolder { destFolder in
                    guard let destFolder = destFolder,
                          let selectedFolder = fileHelper.selectedFolder else { return }

                    var epubInfo = fileHelper.generateEpubInfo()
                    makeBook(folderURL: selectedFolder,
                             epubInfo: &epubInfo,
                             destFolder: destFolder)
                    LogWindowController.shared.openLogWindow()
                }
            }) {
                Text("Make eBook")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .font(.headline)
            }
            .padding(.top, 16)
        }
        .padding()
        // -------------------------------------------------
        //  Sync / load logic
        // -------------------------------------------------
        .onAppear {
            loadEbookSettingsIntoFileHelper()
            syncEbookSettingsFromFileHelper()   // first-time save
        }
        .onChange(of: fileHelper.coverImagePath) { _ in syncEbookSettingsFromFileHelper() }
        .onChange(of: fileHelper.selectedStyleFile) { _ in syncEbookSettingsFromFileHelper() }
        .onChange(of: fileHelper.addedFonts) { _ in syncEbookSettingsFromFileHelper() }
    }
}

// MARK: - Settings <-> FileHelper sync (full paths)

private extension EBookTabView {

    // ---- Load persisted full paths → FileHelper ----
    func loadEbookSettingsIntoFileHelper() {
        // Cover
        if let path = settingsStore.settings.cover,
           FileManager.default.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            fileHelper.coverImagePath = url
            fileHelper.coverImage = NSImage(contentsOf: url)
        }

        // Style
        if let path = settingsStore.settings.style,
           FileManager.default.fileExists(atPath: path) {
            fileHelper.selectedStyleFile = URL(fileURLWithPath: path)
        }

        // Fonts
        if let paths = settingsStore.settings.fonts {
            let urls = paths.compactMap { path -> URL? in
                let url = URL(fileURLWithPath: path)
                return FileManager.default.fileExists(atPath: path) ? url : nil
            }
            fileHelper.addedFonts = urls
        }
    }

    // ---- Save FileHelper → settings + disk (full paths) ----
    func syncEbookSettingsFromFileHelper() {
        // Cover
        settingsStore.settings.cover = fileHelper.coverImagePath?.path

        // Style
        settingsStore.settings.style = fileHelper.selectedStyleFile?.path

        // Fonts
        settingsStore.settings.fonts = fileHelper.addedFonts.isEmpty
            ? nil
            : fileHelper.addedFonts.map(\.path)

        saveSettings()
    }

    func saveSettings() {
        do {
            try settingsStore.save()
            print("EBookTabView: saved cover/style/fonts (full paths)")
        } catch {
            print("EBookTabView: failed to save – \(error)")
        }
    }
}
