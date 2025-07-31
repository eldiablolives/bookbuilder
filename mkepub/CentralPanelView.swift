import SwiftUI

struct CentralPanelView: View {
    @ObservedObject var fileHelper: FileHelper
    @Binding var selectedTab: String

    var body: some View {
        VStack {
            Text("Processor")
                .font(.headline)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.horizontal)
            // Top fields
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    TextField("Book Title", text: $fileHelper.bookTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 8)

                    TextField("Author", text: $fileHelper.author)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 8)

                    
                }
                .padding()
                .border(Color.gray.opacity(0.5), width: 1)
            }
            .padding(.bottom, 16)

            // Selected Files at the bottom
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
        .background(Color.gray.opacity(0.1))
    }
}
