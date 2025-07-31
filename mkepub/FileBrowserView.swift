import SwiftUI

struct FileBrowserView: View {
    @ObservedObject var fileHelper: FileHelper
    @Binding var dividerPosition: CGFloat
    @Binding var isHoveringOverDivider: Bool
    @Binding var initialDividerPosition: CGFloat
    @Binding var dividerPositionRight: CGFloat

    var geometry: GeometryProxy

    // Computed property for indices of displayable files
    private var displayableFileIndices: [Int] {
        fileHelper.filesInFolder.indices.filter { idx in
            let fileURL = fileHelper.filesInFolder[idx]
            let fileExtension = fileURL.pathExtension.lowercased()
            return ["md", "txt", "jpg", "png"].contains(fileExtension)
        }
    }

    // The "select all" binding applies only to displayable files
    private var isAllSelected: Binding<Bool> {
        Binding<Bool>(
            get: {
                !displayableFileIndices.isEmpty &&
                displayableFileIndices.allSatisfy { fileHelper.checkedFiles[$0] }
            },
            set: { newValue in
                for idx in displayableFileIndices {
                    fileHelper.checkedFiles[idx] = newValue
                    let file = fileHelper.filesInFolder[idx]
                    fileHelper.updateSelectedFiles(for: file, isChecked: newValue)
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Source files")
                .font(.headline)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.horizontal)

            List {
                // The master checkbox row at the top of the list
                HStack {
                    Toggle(isOn: isAllSelected) {
                        Text("File name")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.checkbox)
                    Spacer()
                }

                // Then, your files
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
                            .toggleStyle(.checkbox)
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
                    dividerPosition = min(max(initialDividerPosition + deltaX, 0.2), dividerPositionRight - 0.1)
                }
                .onEnded { _ in
                    initialDividerPosition = dividerPosition
                }
        )
    }
}
