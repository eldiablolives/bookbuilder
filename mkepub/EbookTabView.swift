import SwiftUI

struct EBookTabView: View {
    @ObservedObject var fileHelper: FileHelper

    var body: some View {
        VStack {
            Group {
                if let image = fileHelper.coverImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(Text("Clicks to Select Cover Image").foregroundColor(.gray))
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
    }
}
