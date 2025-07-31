import SwiftUI

struct BookBuildView: View {
    @ObservedObject var fileHelper: FileHelper
    @Binding var selectedTab: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("Export Options")
                .font(.headline)
                .padding(.top, 8)

            Picker("", selection: $selectedTab) {
                Text("eBook").tag("eBook")
                Text("HTML").tag("HTML")
                Text("PDF").tag("PDF")
                Text("Print").tag("Print")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // eBook Tab
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

                    Button("Select Style") {
                        fileHelper.openStylePicker()
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

                    Button("Add Font") {
                        fileHelper.openFontPicker()
                    }
                    .padding(.top, 8)

                    Button(action: {
                        fileHelper.selectedBookType = .eBook
                        fileHelper.selectDestinationFolder { destFolder in
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

                    Button(action: {
                        fileHelper.selectedBookType = .printBook
                        fileHelper.selectDestinationFolder { destFolder in
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
    }
}
