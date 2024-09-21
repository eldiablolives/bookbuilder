import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject var fileHelper = FileHelper()
    @State private var selectedTab = "eBook"

    @State private var dividerPosition: CGFloat = 0.3
    @State private var isHoveringOverDivider: Bool = false

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left panel
                VStack {
                    Button(action: {
                        fileHelper.openFolderPicker()
                    }) {
                        Text("Select Folder")
                    }
                    .padding(.top, 8)

                    if let folder = fileHelper.selectedFolder {
                        Text("Selected folder: \(folder.path)")
                            .padding(.top, 8)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Text("All Files")
                        .font(.headline)
                        .padding(.top, 16)

                    List {
                        ForEach(fileHelper.filesInFolder.indices, id: \.self) { index in
                            let fileURL = fileHelper.filesInFolder[index]
                            let fileExtension = fileURL.pathExtension.lowercased()

                            if ["md", "txt", "jpg", "png"].contains(fileExtension) {
                                HStack {
                                    Toggle(isOn: Binding(
                                        get: { fileHelper.checkedFiles[index] },
                                        set: { newValue in
                                            fileHelper.checkedFiles[index] = newValue
                                            fileHelper.updateSelectedFiles(for: fileURL, isChecked: newValue)
                                        })) {
                                        Text(fileURL.lastPathComponent)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width * dividerPosition)
                .background(Color.gray.opacity(0.1))

                Divider()
                    .frame(width: 2)
                    .background(Color.gray)
                    .onHover { hovering in
                        isHoveringOverDivider = hovering
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newDividerPosition = value.location.x / geometry.size.width
                                dividerPosition = min(max(newDividerPosition, 0.2), 0.8)
                            }
                    )

                // Right panel
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            TextField("Book Title", text: $fileHelper.bookTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.top, 8)

                            TextField("Author", text: $fileHelper.author)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.top, 8)

                            Text("Export Options")
                                .font(.headline)
                                .padding(.top, 8)

                            Picker("Export Type", selection: $selectedTab) {
                                Text("eBook").tag("eBook")
                                Text("HTML").tag("HTML")
                                Text("PDF").tag("PDF")
                                Text("Print").tag("Print")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()

                            if selectedTab == "eBook" {
                                VStack {
                                    Group {
                                        if let image = fileHelper.coverImage {
                                            Image(nsImage: image)
                                                .resizable()
                                                .scaledToFit()
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .overlay(Text("Select Cover Image").foregroundColor(.gray))
                                        }
                                    }
                                    .frame(width: 100, height: 150)
                                    .onTapGesture {
                                        fileHelper.openImagePicker()
                                    }
                                    .padding(.bottom, 8)

                                    Button(action: {
                                        fileHelper.openStylePicker()
                                    }) {
                                        Text("Select Style")
                                    }

                                    if let styleFile = fileHelper.selectedStyleFile {
                                        Text("Selected style: \(styleFile.lastPathComponent)")
                                            .font(.caption)
                                            .padding(.top, 4)
                                    }

                                    Text("Added Fonts:")
                                        .font(.headline)
                                        .padding(.top, 8)

                                    List(fileHelper.addedFonts, id: \.self) { font in
                                        Text(font.lastPathComponent)
                                    }
                                    .frame(height: 100)

                                    Button(action: {
                                        fileHelper.openFontPicker()
                                    }) {
                                        Text("Add Font")
                                    }
                                    .padding(.top, 8)

                                    // Make eBook button with destination folder selection
                                    Button(action: {
                                        fileHelper.selectedBookType = .eBook
                                        selectDestinationFolder { destFolder in
                                            guard let destFolder = destFolder, let selectedFolder = fileHelper.selectedFolder else { return }

                                            var epubInfo = fileHelper.generateEpubInfo()
                                            makeBook(folderURL: selectedFolder, epubInfo: &epubInfo, destFolder: destFolder)
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
                            } else if selectedTab == "Print" {
                                VStack {
                                    Text("Print Options")
                                        .font(.subheadline)
                                        .padding()

                                    // Make Print Book button with destination folder selection
                                    Button(action: {
                                        fileHelper.selectedBookType = .printBook
                                        selectDestinationFolder { destFolder in
                                            guard let destFolder = destFolder, let selectedFolder = fileHelper.selectedFolder else { return }

                                            var epubInfo = fileHelper.generateEpubInfo()
                                            makeTeXBook(folderURL: selectedFolder, epubInfo: &epubInfo, destFolder: destFolder)
                                            LogWindowController.shared.openLogWindow()
                                        }
                                    }) {
                                        Text("Make Print Book")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .foregroundColor(.white)
                                            .background(Color.green)
                                            .cornerRadius(10)
                                            .font(.headline)
                                    }
                                    .padding(.top, 16)
                                }
                            }
                        }
                        .padding()
                        .border(Color.gray.opacity(0.5), width: 1)
                    }
                    .padding(.bottom, 16)

                    VStack {
                        Text("Selected Files")
                            .font(.headline)
                        List(fileHelper.selectedFiles, id: \.self) { file in
                            Text(file.lastPathComponent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .padding()
            }
        }
    }

    // Helper function to open folder picker for destination folder
    func selectDestinationFolder(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK {
                completion(panel.url) // Return the selected folder URL
            } else {
                completion(nil) // User canceled
            }
        }
    }
}

#Preview {
    ContentView()
}
