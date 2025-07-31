import SwiftUI

struct CentralPanelView: View {
    @ObservedObject var fileHelper: FileHelper
    @Binding var selectedTab: String
    @EnvironmentObject var settingsStore: SettingsStore

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
                    // --- Bind directly to config ---
                    TextField("Book Title", text: Binding(
                        get: { settingsStore.settings.title ?? "" },
                        set: { settingsStore.settings.title = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top, 8)

                    TextField("Author", text: Binding(
                        get: { settingsStore.settings.author ?? "" },
                        set: { settingsStore.settings.author = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top, 8)
                }
                .padding()
                .border(Color.gray.opacity(0.5), width: 1)
            }
            .padding(.bottom, 16)

            // Selected Files at the bottom (still uses fileHelper)
            VStack {
                Text("[\(fileHelper.selectedFiles.count)] Selected files, (\(settingsStore.settings.words ?? 0) words)")
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
