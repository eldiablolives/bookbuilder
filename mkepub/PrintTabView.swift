import SwiftUI

struct PrintTabView: View {
    @ObservedObject var fileHelper: FileHelper
    @EnvironmentObject var settingsStore: SettingsStore

    let targets = ["Amazon KDP", "IngramSparks", "Lulu", "Custom"]
    let fonts = ["Garamond", "Pagella"]

    let trimSizes: [String: [String]] = [
        "Amazon KDP": [
            "5\" x 8\"", "5.25\" x 8\"", "5.5\" x 8.5\"", "6\" x 9\"",
            "6.14\" x 9.21\"", "6.69\" x 9.61\"", "7\" x 10\"",
            "7.44\" x 9.69\"", "7.5\" x 9.25\"", "8\" x 10\"",
            "8.25\" x 6\"", "8.25\" x 8.25\"", "8.25\" x 11\"", "8.5\" x 8.5\"", "8.5\" x 11\"", "8.27\" x 11.69\""
        ],
        "IngramSparks": [
            "4.25\" x 7\"", "4.37\" x 7\"", "5\" x 8\"", "5.25\" x 8\"", "5.5\" x 8.5\"",
            "5.83\" x 8.27\"", "6\" x 9\"", "6.14\" x 9.21\"", "6.5\" x 6.5\"", "6.69\" x 9.61\"",
            "7\" x 10\"", "7.44\" x 9.69\"", "7.5\" x 9.25\"", "7.5\" x 10\"", "8\" x 8\"", "8\" x 10\"",
            "8.25\" x 6\"", "8.25\" x 8.25\"", "8.25\" x 10.75\"", "8.25\" x 11\"", "8.27\" x 11.69\"",
            "8.5\" x 8.5\"", "8.5\" x 11\""
        ],
        "Lulu": [
            "4.25\" x 6.87\"", "5\" x 8\"", "5.5\" x 8.5\"", "6\" x 9\"", "6.14\" x 9.21\"", "6.69\" x 9.61\"",
            "7\" x 10\"", "8\" x 10\"", "8.25\" x 10.75\"", "8.5\" x 8.5\"", "8.5\" x 11\""
        ],
        "Custom": [
            "Custom size..."
        ]
    ]

    var currentTrimSizes: [String] {
        trimSizes[settingsStore.settings.printTarget ?? "Amazon KDP"] ?? ["Custom size..."]
    }

    // Bindings for all fields
    private var selectedTarget: Binding<String> {
        Binding(
            get: { settingsStore.settings.printTarget ?? "Amazon KDP" },
            set: { settingsStore.settings.printTarget = $0 }
        )
    }
    private var selectedTrimSize: Binding<String> {
        Binding(
            get: { settingsStore.settings.printTrimSize ?? currentTrimSizes.first ?? "" },
            set: { settingsStore.settings.printTrimSize = $0 }
        )
    }
    private var selectedFont: Binding<String> {
        Binding(
            get: { settingsStore.settings.printFont ?? "Garamond" },
            set: { settingsStore.settings.printFont = $0 }
        )
    }
    private var marginTop: Binding<String> {
        Binding(
            get: { settingsStore.settings.marginTop ?? "20" },
            set: { settingsStore.settings.marginTop = $0 }
        )
    }
    private var marginBottom: Binding<String> {
        Binding(
            get: { settingsStore.settings.marginBottom ?? "20" },
            set: { settingsStore.settings.marginBottom = $0 }
        )
    }
    private var marginInner: Binding<String> {
        Binding(
            get: { settingsStore.settings.marginInner ?? "18" },
            set: { settingsStore.settings.marginInner = $0 }
        )
    }
    private var marginOuter: Binding<String> {
        Binding(
            get: { settingsStore.settings.marginOuter ?? "15" },
            set: { settingsStore.settings.marginOuter = $0 }
        )
    }
    private var gutter: Binding<String> {
        Binding(
            get: { settingsStore.settings.gutter ?? "0" },
            set: { settingsStore.settings.gutter = $0 }
        )
    }
    private var fontSize: Binding<String> {
        Binding(
            get: { settingsStore.settings.fontSize ?? "11" },
            set: { settingsStore.settings.fontSize = $0 }
        )
    }
    private var lineSpacing: Binding<String> {
        Binding(
            get: { settingsStore.settings.lineSpacing ?? "1.2" },
            set: { settingsStore.settings.lineSpacing = $0 }
        )
    }
    private var bleedWidth: Binding<String> {
        Binding(
            get: { settingsStore.settings.bleedWidth ?? "0.125" },
            set: { settingsStore.settings.bleedWidth = $0 }
        )
    }
    private var bleedHeight: Binding<String> {
        Binding(
            get: { settingsStore.settings.bleedHeight ?? "0.125" },
            set: { settingsStore.settings.bleedHeight = $0 }
        )
    }
    private var bleedMargin: Binding<String> {
        Binding(
            get: { settingsStore.settings.bleedMargin ?? "0.0" },
            set: { settingsStore.settings.bleedMargin = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Print Options")
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.top, 10)

                HStack {
                    Text("Target:")
                        .font(.body)
                    Picker("Target", selection: selectedTarget) {
                        ForEach(targets, id: \.self) { target in
                            Text(target)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    .frame(maxWidth: 200)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
                .onChange(of: settingsStore.settings.printTarget) { _ in
                    selectedTrimSize.wrappedValue = currentTrimSizes.first ?? ""
                }

                HStack {
                    Text("Trim size:")
                        .font(.body)
                    Picker("Trim Size", selection: selectedTrimSize) {
                        ForEach(currentTrimSizes, id: \.self) { size in
                            Text(size)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    .frame(maxWidth: 200)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                HStack {
                    Text("Font:")
                        .font(.body)
                    Picker("Font", selection: selectedFont) {
                        ForEach(fonts, id: \.self) { font in
                            Text(font)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    .frame(maxWidth: 200)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
                
                
                HStack {
                    Text("Font size:")
                        .font(.body)
                    TextField("Font size", text: fontSize)
                        .frame(width: 50)
                    Spacer()
                    Text("Line spacing:")
                        .font(.body)
                    TextField("Line spacing", text: lineSpacing)
                        .frame(width: 50)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)


                // Margins section
                GroupBox(label: Text("Margins").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Top:")
                            TextField("Top", text: marginTop)
                                .frame(width: 50)
                            Spacer()
                            Text("Bottom:")
                            TextField("Bottom", text: marginBottom)
                                .frame(width: 50)
                        }
                        HStack {
                            Text("Inner:")
                            TextField("Inner", text: marginInner)
                                .frame(width: 50)
                            Spacer()
                            Text("Outer:")
                            TextField("Outer", text: marginOuter)
                                .frame(width: 50)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                HStack {
                    Text("Gutter:")
                        .font(.body)
                    TextField("Gutter", text: gutter)
                        .frame(width: 50)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                // Bleed section
                GroupBox(label: Text("Bleed area").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Width:")
                            TextField("Width", text: bleedWidth)
                                .frame(width: 50)
                            Spacer()
                            Text("Height:")
                            TextField("Height", text: bleedHeight)
                                .frame(width: 50)
                        }
                        HStack {
                            Text("Margin:")
                            TextField("Margin", text: bleedMargin)
                                .frame(width: 50)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                Button(action: {
                    fileHelper.selectedBookType = .printBook
                    // Use all the above settings in your logic here
                    fileHelper.selectDestinationFolder { destFolder in
                        guard let destFolder = destFolder, let selectedFolder = fileHelper.selectedFolder else { return }
                        var epubInfo = fileHelper.generateEpubInfo()
                        // Pass settings (selectedFont, marginTop, bleedWidth, etc.) as needed!
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
                .padding(.horizontal)
            }
        }
        .onAppear {
            // Set trim size to the first for selected target if not already set
            if settingsStore.settings.printTrimSize == nil || settingsStore.settings.printTrimSize == "" {
                selectedTrimSize.wrappedValue = currentTrimSizes.first ?? ""
            }
        }
    }
}
