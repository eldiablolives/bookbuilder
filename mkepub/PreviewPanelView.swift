import SwiftUI

struct PreviewPanelView: View {
    @Binding var rightPanelTab: String
    @Binding var sourceText: String
    @Binding var htmlContent: String
    @Binding var dividerPositionRight: CGFloat
    var geometry: GeometryProxy

    var body: some View {
        VStack {
            // Tab bar for "Source" and "Preview"
            Picker("", selection: $rightPanelTab) {
                Text("Source").tag("Source")
                Text("Preview").tag("Preview")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Content based on selected tab
            if rightPanelTab == "Source" {
                ScrollView {
                    Text(sourceText.isEmpty ? "No content available" : sourceText)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .background(Color.white)
                .border(Color.gray.opacity(0.5), width: 1)
            } else if rightPanelTab == "Preview" {
//                WebView(htmlContent: htmlContent)
//                    .border(Color.gray.opacity(0.5), width: 1)
            }
        }
    }
}
