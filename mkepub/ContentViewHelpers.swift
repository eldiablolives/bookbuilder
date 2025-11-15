import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit

enum BookType: String, CaseIterable {
    case eBook = "eBook"
    case printBook = "Print"
}

enum PreviewType {
    case text(content: String)
    case image(content: NSImage)
    case pdf(content: PDFDocument)
    case html(content: String)
}

struct FilePreview {
    let type: PreviewType
    let filePath: String
}

// --- FileHelper below ---

class FileHelper: ObservableObject {
    @Published var selectedFolder: URL? = nil
    @Published var filesInFolder: [URL] = []
    @Published var checkedFiles: [Bool] = []
    @Published var selectedFiles: [URL] = []
    @Published var coverImage: NSImage? = nil
    @Published var coverImagePath: URL? = nil
    @Published var addedFonts: [URL] = []
    @Published var addedImages: [URL] = []

    // Book properties
    @Published var useCurlyQuotes: Bool = false
    @Published var selectedBookType: BookType = .eBook
    @Published var selectedStyleFile: URL? = nil

    // Store reference
    weak var settingsStore: SettingsStore?

    // MARK: - Folder Picker

    func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            selectedFolder = panel.url
            if let folderURL = selectedFolder {
                readFolderContents(at: folderURL)
            }
        }
    }

    // MARK: - Folder Reader

    func readFolderContents(at url: URL) {
        do {
            let fileManager = FileManager.default
            let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

            let files = items.filter { item in
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory)
                return !isDirectory.boolValue
            }
            .sorted(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() })

            filesInFolder = files
            checkedFiles = Array(repeating: false, count: files.count)
            selectedFiles = []
            settingsStore?.settings.words = 0

            settingsStore?.load(from: url)

        } catch {
            print("Error reading folder contents: \(error)")
            filesInFolder = []
            checkedFiles = []
            selectedFiles = []
            settingsStore?.settings.words = 0
        }
    }

    // MARK: - Update selection and words

    func updateSelectedFiles(for file: URL, isChecked: Bool) {
        if isChecked {
            selectedFiles.append(file)
        } else {
            selectedFiles.removeAll { $0 == file }
        }
        recalculateTotalSelectedWords()
    }

    private func recalculateTotalSelectedWords() {
        guard let settingsStore = settingsStore else { return }
        let wordCount = selectedFiles
            .filter { ["txt", "md", "html", "htm"].contains($0.pathExtension.lowercased()) }
            .compactMap { try? String(contentsOf: $0, encoding: .utf8) }
            .map { $0.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count }
            .reduce(0, +)
        settingsStore.settings.words = wordCount
    }

    // MARK: - Reusable File Picker (macOS 12+ safe)

    private func openFilePicker(
        title: String? = nil,
        allowedExtensions: [String],
        allowsMultipleSelection: Bool = false,
        completion: @escaping ([URL]) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = allowsMultipleSelection

        // Convert extensions → UTType safely (macOS 12+)
        let contentTypes = allowedExtensions.compactMap { UTType(filenameExtension: $0) }
        panel.allowedContentTypes = contentTypes.isEmpty ? [.item] : contentTypes

        if panel.runModal() == .OK {
            completion(panel.urls)
        } else {
            completion([])
        }
    }

    // MARK: - Image Picker

    func openImagePicker() {
        openFilePicker(
            title: "Select Cover Image",
            allowedExtensions: ["png", "jpg", "jpeg", "gif", "bmp", "tiff"],
            allowsMultipleSelection: false
        ) { urls in
            guard let url = urls.first else { return }
            self.loadImage(from: url)
        }
    }

    func loadImage(from url: URL) {
        if let image = NSImage(contentsOf: url) {
            coverImage = image
            coverImagePath = url
            if !addedImages.contains(url) {
                addedImages.append(url)
            }
        }
    }

    // MARK: - Style Picker

    func openStylePicker() {
        openFilePicker(
            title: "Select Style File",
            allowedExtensions: ["css", "html", "htm"],
            allowsMultipleSelection: false
        ) { urls in
            self.selectedStyleFile = urls.first
        }
    }

    // MARK: - Font Picker (MULTI-SELECT ENABLED)

    func openFontPicker() {
        openFilePicker(
            title: "Select Fonts",
            allowedExtensions: ["ttf", "otf", "woff", "woff2"],
            allowsMultipleSelection: true
        ) { urls in
            let newFonts = urls.filter { !self.addedFonts.contains($0) }
            self.addedFonts.append(contentsOf: newFonts)
        }
    }

    // MARK: - EpubInfo

    func generateEpubInfo() -> EpubInfo {
        func isImageFile(_ url: URL) -> Bool {
            let imageExtensions = ["jpg", "jpeg", "png"]
            return imageExtensions.contains(url.pathExtension.lowercased())
        }
        var images = addedImages.map { $0.standardizedFileURL.path }
        if let coverImagePath = coverImagePath?.standardizedFileURL.path {
            images.append(coverImagePath)
        }
        let documentImages = selectedFiles
            .filter { isImageFile($0) }
            .map { $0.standardizedFileURL.path }
        let allImages = Array(Set(images + documentImages))
        return EpubInfo(
            id: UUID().uuidString,
            name:   (settingsStore?.settings.title?.isEmpty == false ? settingsStore?.settings.title : nil) ?? "Untitled",
            author: (settingsStore?.settings.author?.isEmpty == false ? settingsStore?.settings.author : nil) ?? "Unknown",
            title:  (settingsStore?.settings.title?.isEmpty == false ? settingsStore?.settings.title : nil) ?? "Untitled",
            start: nil,
            startTitle: nil,
            cover: coverImagePath?.standardizedFileURL.path,
            style: selectedStyleFile?.path,
            fonts: addedFonts.map { $0.path },
            images: allImages,
            documents: selectedFiles.map { $0.path }
        )
    }

    // MARK: - Preview

    func getPreview(for path: String) -> FilePreview? {
        let fileURL = URL(fileURLWithPath: path)
        let fileExtension = fileURL.pathExtension.lowercased()
        do {
            switch fileExtension {
            case "txt", "md":
                let textContent = try String(contentsOf: fileURL, encoding: .utf8)
                return FilePreview(type: .text(content: textContent), filePath: path)
            case "html", "htm":
                let htmlContent = try String(contentsOf: fileURL, encoding: .utf8)
                return FilePreview(type: .html(content: htmlContent), filePath: path)
            case "jpg", "jpeg", "png":
                if let image = NSImage(contentsOf: fileURL) {
                    return FilePreview(type: .image(content: image), filePath: path)
                }
            case "pdf":
                if let pdfDocument = PDFDocument(url: fileURL) {
                    return FilePreview(type: .pdf(content: pdfDocument), filePath: path)
                }
            default:
                print("Unsupported file type: \(fileExtension)")
            }
        } catch {
            print("Error loading file: \(error)")
        }
        return nil
    }

    // MARK: - Destination Picker

    func selectDestinationFolder(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK {
                completion(panel.url)
            } else {
                completion(nil)
            }
        }
    }
}
