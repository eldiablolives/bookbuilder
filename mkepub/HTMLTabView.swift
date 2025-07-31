import SwiftUI

struct HTMLTabView: View {
    @ObservedObject var fileHelper: FileHelper

    var body: some View {
        VStack(alignment: .leading) {
            Text("HTML Export Options")
                .font(.headline)
                .padding(.bottom, 8)

            Button(action: {
                fileHelper.selectedBookType = .eBook // or a custom type if you add one for HTML
                fileHelper.selectDestinationFolder { destFolder in
                    guard let destFolder = destFolder, let selectedFolder = fileHelper.selectedFolder else { return }
                    var epubInfo = fileHelper.generateEpubInfo()
                    // Replace with your own HTML export logic!
//                    makeHTMLBook(folderURL: selectedFolder, epubInfo: &epubInfo, destFolder: destFolder)
                    LogWindowController.shared.openLogWindow()
                }
            }) {
                Text("Export as HTML")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .font(.headline)
            }
            .padding(.top, 16)
        }
    }
}
