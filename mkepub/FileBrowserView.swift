import SwiftUI

struct FileBrowserView: View {
    @ObservedObject var fileHelper: FileHelper
    @Binding var dividerPosition: CGFloat
    @Binding var isHoveringOverDivider: Bool
    @Binding var initialDividerPosition: CGFloat
    @Binding var dividerPositionRight: CGFloat

    var geometry: GeometryProxy

    var body: some View {
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
    }
}
