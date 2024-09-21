import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject var fileHelper = FileHelper()
    @State private var selectedTab = "eBook"   // For Export Types tab
    @State private var rightPanelTab = "Source"   // For the rightmost panel tabs
    @State private var sourceText = ""   // Plain text content for Source tab
    @State private var htmlContent = ""  // HTML content for Preview tab
    
    @State private var dividerPosition: CGFloat = 0.3  // Left divider
    @State private var dividerPositionRight: CGFloat = 0.7  // Right divider
    @State private var isHoveringOverDivider: Bool = false
    @State private var initialDividerPosition: CGFloat = 0.3
    @State private var initialDividerPositionRight: CGFloat = 0.7

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left panel extracted to LeftPanelView
                LeftPanelView(
                    fileHelper: fileHelper,
                    dividerPosition: $dividerPosition,
                    isHoveringOverDivider: $isHoveringOverDivider,
                    initialDividerPosition: $initialDividerPosition,
                    dividerPositionRight: $dividerPositionRight,
                    geometry: geometry
                )
                .frame(width: geometry.size.width * dividerPosition)
                .background(Color.gray.opacity(0.1))

                // First Divider
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
                                let totalWidth = geometry.size.width
                                let deltaX = value.translation.width / totalWidth
                                dividerPosition = min(max(initialDividerPosition + deltaX, 0.2), dividerPositionRight - 0.1) // Prevent overlap
                            }
                            .onEnded { _ in
                                initialDividerPosition = dividerPosition
                            }
                    )

                // Middle panel (existing content)
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

                            Picker("", selection: $selectedTab) {
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
                .frame(width: geometry.size.width * (dividerPositionRight - dividerPosition))
                .background(Color.gray.opacity(0.1))

                // Second Divider (rightmost divider)
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
                                let totalWidth = geometry.size.width
                                let deltaX = value.translation.width / totalWidth
                                dividerPositionRight = min(max(initialDividerPositionRight + deltaX, dividerPosition + 0.1), 0.8) // Prevent overlap
                            }
                            .onEnded { _ in
                                initialDividerPositionRight = dividerPositionRight
                            }
                    )

                // Rightmost panel extracted to RightPanelView
                RightPanelView(
                    rightPanelTab: $rightPanelTab,
                    sourceText: $sourceText,
                    htmlContent: $htmlContent,
                    dividerPositionRight: $dividerPositionRight,
                    geometry: geometry
                )
                .frame(width: geometry.size.width * (1 - dividerPositionRight))
                .background(Color.gray.opacity(0.1))
            }
        }
    }
}

struct WebView: NSViewRepresentable {
    var htmlContent: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

#Preview {
    ContentView()
}
