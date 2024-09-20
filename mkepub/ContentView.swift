import SwiftUI
import AppKit
import UniformTypeIdentifiers // Import for UTType
import Foundation // Import the Foundation for calling the external function

//// Assume makeBook() is defined in a different file
//func makeBook() {
//    // This is a placeholder
//    print("Book creation started")
//}

enum BookType: String, CaseIterable {
    case eBook = "eBook"
    case printBook = "Print"
}

struct ContentView: View {
    @State private var selectedFolder: URL? = nil
    @State private var filesInFolder: [URL] = [] // Store as URL to keep the full path
    @State private var checkedFiles: [Bool] = [] // Track whether each file is checked
    @State private var selectedFiles: [URL] = [] // Store selected files as URLs for absolute paths
    @State private var bookTitle: String = ""
    @State private var author: String = ""
    @State private var coverImage: NSImage? = nil
    @State private var coverImagePath: URL? = nil // Store the full path
    @State private var useCurlyQuotes: Bool = false
    @State private var selectedBookType: BookType = .eBook
    @State private var selectedStyleFile: URL? = nil // Store the full path for the style file
    @State private var addedFonts: [URL] = [] // Store fonts as URLs for absolute paths
    @State private var addedImages: [URL] = [] // Store image URLs (including the cover image)

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Group {
                        if let image = coverImage {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(Text("Select Cover Image").foregroundColor(.gray))
                        }
                    }
                    .frame(width: 150, height: 100)
                    .onTapGesture {
                        openImagePicker()
                    }
                    .padding(.bottom, 8)

                    TextField("Book Title", text: $bookTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 8)

                    TextField("Author", text: $author)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 8)

                    Button(action: openFolderPicker) {
                        Text("Select Folder")
                    }
                    .padding(.top, 8)

                    if let folder = selectedFolder {
                        Text("Selected folder: \(folder.path)")
                            .padding(.top, 8)
                    }
                }
                .padding()
                .border(Color.gray.opacity(0.5), width: 1)

                VStack(alignment: .leading) {
                    Toggle(isOn: $useCurlyQuotes) {
                        Text("Curly quotes")
                    }
                    .padding(.bottom, 8)

                    Picker("Book Type", selection: $selectedBookType) {
                        ForEach(BookType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .padding(.bottom, 8)

                    Button(action: openStylePicker) {
                        Text("Select Style")
                    }

                    if let styleFile = selectedStyleFile {
                        Text("Selected style: \(styleFile.lastPathComponent)")
                            .font(.caption)
                            .padding(.top, 4)
                    }

                    Text("Added Fonts:")
                        .font(.headline)
                        .padding(.top, 8)

                    List(addedFonts, id: \.self) { font in
                        Text(font.lastPathComponent)
                    }
                    .frame(height: 100)

                    Button(action: openFontPicker) {
                        Text("Add Font")
                    }
                    .padding(.top, 8)

                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false

                        panel.begin { response in
                            guard response == .OK, let selectedFolder = panel.url else {
                                logger.log("No folder selected or selection cancelled.")
                                return
                            }

                            // Folder was selected, now execute the rest of the code.
                            logger.log("Folder URL: \(selectedFolder)")

                            // Call the function to generate the EpubInfo object
                            var epubInfo = generateEpubInfo()

                            // Check the selected book type
                            if selectedBookType == .eBook {
                                // Proceed with eBook creation
                                makeBook(folderURL: selectedFolder, epubInfo: &epubInfo, destFolder: selectedFolder)
                                logger.log("eBook creation finished.")
                            } else if selectedBookType == .printBook {
                                // Proceed with print book creation
                                makeTeXBook(folderURL: selectedFolder, epubInfo: &epubInfo, destFolder: selectedFolder)
                                logger.log("Print book creation finished.")
                            }

                            // Open log window
                            LogWindowController.shared.openLogWindow()
                        }
                    }) {
                        Text("Make a Book")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.headline)
                    }
                    .padding(.top, 16)
                }
                .frame(width: 200)
                .padding()
                .border(Color.gray.opacity(0.5), width: 1)
            }
            .padding(.bottom, 16)

            HStack {
                VStack {
                    Text("All Files")
                        .font(.headline)
                    List {
                        ForEach(filesInFolder.indices, id: \.self) { index in
                            let fileURL = filesInFolder[index]
                            let fileExtension = fileURL.pathExtension.lowercased()

                            // Check if the file has the desired extensions
                            if ["md", "txt", "jpg", "png"].contains(fileExtension) {
                                HStack {
                                    Toggle(isOn: Binding(
                                        get: { checkedFiles[index] },
                                        set: { newValue in
                                            checkedFiles[index] = newValue
                                            updateSelectedFiles(for: fileURL, isChecked: newValue)
                                        })) {
                                        Text(fileURL.lastPathComponent)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("Selected Files")
                        .font(.headline)
                    List(selectedFiles, id: \.self) { file in
                        Text(file.lastPathComponent)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .padding()
    }

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

    // Function to open image picker for JPG images
    func openImagePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.jpeg, UTType.png]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
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
            addedFonts.append(url) // Store absolute path
        }
    }

    // Function to load the selected cover image
    func loadImage(from url: URL) {
        if let image = NSImage(contentsOf: url) {
            coverImage = image
            coverImagePath = url // Store absolute path

            // Add the cover image to the list of images
            if !addedImages.contains(url) {
                addedImages.append(url)
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

    // Function to generate and return the EpubInfo object
    // Function to generate and return the EpubInfo object
    func generateEpubInfo() -> EpubInfo {
        // Add cover image to images only if it exists and is not already in addedImages
        var images = addedImages.map { $0.path }
        if let coverImagePath = coverImagePath, !images.contains(coverImagePath.path) {
            images.append(coverImagePath.path) // Include cover image in images only if not already present
        }

        // Generate and return EpubInfo
        return EpubInfo(
            id: UUID().uuidString,
            name: bookTitle.isEmpty ? "Untitled Book" : bookTitle,
            author: author.isEmpty ? "Unknown Author" : author,
            title: bookTitle.isEmpty ? "Untitled Book" : bookTitle,
            start: nil,
            startTitle: nil,
            cover: coverImagePath?.path, // Absolute path for the cover image
            style: selectedStyleFile?.path, // Absolute path for style file
            fonts: addedFonts.map { $0.path }, // Absolute paths for fonts
            images: images, // Add cover and other images
            documents: selectedFiles.map { $0.path } // Only selected files as documents
        )
    }
}

#Preview {
    ContentView()
}
