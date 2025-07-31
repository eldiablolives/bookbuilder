import SwiftUI

struct PDFTabView: View {
    @ObservedObject var fileHelper: FileHelper

    var body: some View {
        VStack(alignment: .leading) {
            Text("PDF Export Options")
                .font(.headline)
                .padding(.bottom, 8)

            Button(action: {
                fileHelper.selectedBookType = .eBook // or a custom type if needed
                fileHelper.selectDestinationFolder { destFolder in
                    guard let destFolder = destFolder, let selectedFolder = fileHelper.selectedFolder else { return }
                    var epubInfo = fileHelper.generateEpubInfo()
                    // Replace with your own PDF export logic!
//                    makePDFBook(folderURL: selectedFolder, epubInfo: &epubInfo, destFolder: destFolder)
                    LogWindowController.shared.openLogWindow()
                }
            }) {
                Text("Export as PDF")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.purple)
                    .cornerRadius(10)
                    .font(.headline)
            }
            .padding(.top, 16)
        }
    }
}
