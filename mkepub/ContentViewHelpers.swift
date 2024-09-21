import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum BookType: String, CaseIterable {
    case eBook = "eBook"
    case printBook = "Print"
}

class FileHelper: ObservableObject {
    @Published var selectedFolder: URL? = nil
    @Published var filesInFolder: [URL] = []
    @Published var checkedFiles: [Bool] = []
    @Published var selectedFiles: [URL] = []
    @Published var coverImage: NSImage? = nil
    @Published var coverImagePath: URL? = nil
    @Published var addedFonts: [URL] = []
    @Published var addedImages: [URL] = []
    
    // Properties for Book Title, Author, and other options
    @Published var bookTitle: String = ""
    @Published var author: String = ""
    @Published var useCurlyQuotes: Bool = false
    @Published var selectedBookType: BookType = .eBook
    @Published var selectedStyleFile: URL? = nil
    
    // Function to open folder picker
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

    // Function to read folder contents
    func readFolderContents(at url: URL) {
        do {
            let fileManager = FileManager.default
            let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

            let files = items.filter { item in
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory)
                return !isDirectory.boolValue
            }
            .sorted(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }) // Sort by file name

            filesInFolder = files
            checkedFiles = Array(repeating: false, count: files.count)
            selectedFiles = []
        } catch {
            print("Error reading folder contents: \(error)")
            filesInFolder = []
            checkedFiles = []
            selectedFiles = []
        }
    }

    // Function to update selected files based on the checkbox state
    func updateSelectedFiles(for file: URL, isChecked: Bool) {
        if isChecked {
            selectedFiles.append(file)
        } else {
            selectedFiles.removeAll { $0 == file }
        }
    }

    // Function to open image picker for JPG/PNG images
    func openImagePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.jpeg, UTType.png]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
        }
    }

    // Function to load the selected cover image
    func loadImage(from url: URL) {
        if let image = NSImage(contentsOf: url) {
            coverImage = image
            coverImagePath = url

            // Add the cover image to the list of images
            if !addedImages.contains(url) {
                addedImages.append(url)
            }
        }
    }

    // Function to open file picker for CSS files
    func openStylePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType(filenameExtension: "css")!]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            selectedStyleFile = panel.url
        }
    }

    // Function to open file picker for OTF font files
    func openFontPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType(filenameExtension: "otf")!]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            addedFonts.append(url)
        }
    }

    // Function to generate and return the EpubInfo object
    func generateEpubInfo() -> EpubInfo {
        var images = addedImages.map { $0.path }
        if let coverImagePath = coverImagePath?.path {
            images.append(coverImagePath)
        }

        return EpubInfo(
            id: UUID().uuidString,
            name: bookTitle.isEmpty ? "Untitled Book" : bookTitle,
            author: author.isEmpty ? "Unknown Author" : author,
            title: bookTitle.isEmpty ? "Untitled Book" : bookTitle,
            start: nil,
            startTitle: nil,
            cover: coverImagePath?.path,
            style: selectedStyleFile?.path,
            fonts: addedFonts.map { $0.path },
            images: images,
            documents: selectedFiles.map { $0.path }
        )
    }
}
