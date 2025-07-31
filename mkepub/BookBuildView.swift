import SwiftUI

struct BookBuildView: View {
    @ObservedObject var fileHelper: FileHelper
    @Binding var selectedTab: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("Publisher")
                .font(.headline)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.horizontal)

            Picker("", selection: $selectedTab) {
                Text("eBook").tag("eBook")
                Text("HTML").tag("HTML")
                Text("PDF").tag("PDF")
                Text("Print").tag("Print")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            switch selectedTab {
            case "eBook":
                EBookTabView(fileHelper: fileHelper)
            case "HTML":
                HTMLTabView(fileHelper: fileHelper)
            case "PDF":
                PDFTabView(fileHelper: fileHelper)
            case "Print":
                PrintTabView(fileHelper: fileHelper)
            default:
                EmptyView()
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
