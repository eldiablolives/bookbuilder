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
    @Published var bookTitle: String = ""
    @Published var author: String = ""
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
            settingsStore?.settings.words = 0 // reset total words
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

    // MARK: - Image Picker

    func openImagePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.jpeg, UTType.png]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
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

    // MARK: - Style/Font Picker

    func openStylePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType(filenameExtension: "css")!]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            selectedStyleFile = panel.url
        }
    }

    func openFontPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType(filenameExtension: "otf")!]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            addedFonts.append(url)
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
            name: bookTitle.isEmpty ? "Untitled Book" : bookTitle,
            author: author.isEmpty ? "Unknown Author" : author,
            title: bookTitle.isEmpty ? "Untitled Book" : bookTitle,
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
            case "jpg", "png":
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
