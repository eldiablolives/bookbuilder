import SwiftUI

struct FileBrowserView: View {
    @ObservedObject var fileHelper: FileHelper
    @Binding var dividerPosition: CGFloat
    @Binding var isHoveringOverDivider: Bool
    @Binding var initialDividerPosition: CGFloat
    @Binding var dividerPositionRight: CGFloat

    var geometry: GeometryProxy

    // MARK: - Displayable Files (filtered by extension)
    private var displayableFileIndices: [Int] {
        fileHelper.filesInFolder.indices.filter { idx in
            let fileURL = fileHelper.filesInFolder[idx]
            let ext = fileURL.pathExtension.lowercased()
            return ["md", "txt", "jpg", "png"].contains(ext)
        }
    }

    // MARK: - "Select All" for displayable files only
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
                // Master checkbox
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

                // Individual files
                ForEach(fileHelper.filesInFolder.indices, id: \.self) { index in
                    let fileURL = fileHelper.filesInFolder[index]
                    let ext = fileURL.pathExtension.lowercased()

                    if ["md", "txt", "jpg", "png"].contains(ext) {
                        HStack {
                            Toggle(isOn: Binding(
                                get: { fileHelper.checkedFiles[index] },
                                set: { newValue in
                                    fileHelper.checkedFiles[index] = newValue
                                    fileHelper.updateSelectedFiles(for: fileURL, isChecked: newValue)
                                }
                            )) {
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
        // MARK: - Auto-load checked state from settings when folder changes
        .onChange(of: fileHelper.selectedFolder) { _ in
            restoreCheckedFilesFromSettings()
        }
        // Also restore on first appear (in case folder was pre-loaded)
        .onAppear {
            restoreCheckedFilesFromSettings()
        }
    }

    // MARK: - Restore checked state from saved filenames
    private func restoreCheckedFilesFromSettings() {
        guard let folder = fileHelper.selectedFolder else { return }

        // Get saved filenames from settings (relative to folder)
        let savedFilenames = fileHelper.settingsStore?.settings.files ?? []

        // Reset all checkboxes
        fileHelper.checkedFiles = Array(repeating: false, count: fileHelper.filesInFolder.count)

        // Match saved filenames → mark as checked
        for (index, fileURL) in fileHelper.filesInFolder.enumerated() {
            let filename = fileURL.lastPathComponent
            if savedFilenames.contains(filename) {
                fileHelper.checkedFiles[index] = true
                fileHelper.updateSelectedFiles(for: fileURL, isChecked: true)
            }
        }
    }
}
