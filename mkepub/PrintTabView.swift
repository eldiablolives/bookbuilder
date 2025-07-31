import SwiftUI

struct KDPTrimSpec {
    let trim: String
    let marginTop: String
    let marginBottom: String
    let marginInner: String
    let marginOuter: String
    let gutter: String
    let bleedWidth: String
    let bleedHeight: String
    let bleedMargin: String
    let minPages: Int
    let maxPages: Int
}

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

    let kdpSpecs: [KDPTrimSpec] = [
        KDPTrimSpec(trim: "5 x 8", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "5.25", bleedHeight: "8.25", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "5.06 x 7.81", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "5.31", bleedHeight: "8.06", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "5.25 x 8", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "5.5", bleedHeight: "8.25", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "5.5 x 8.5", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "5.75", bleedHeight: "8.75", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "6 x 9", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "6.25", bleedHeight: "9.25", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "6.14 x 9.21", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "6.39", bleedHeight: "9.46", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "6.69 x 9.61", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "6.94", bleedHeight: "9.86", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "7 x 10", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "7.25", bleedHeight: "10.25", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "7.44 x 9.69", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "7.69", bleedHeight: "9.94", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "7.5 x 9.25", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "7.75", bleedHeight: "9.5", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "8 x 10", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "8.25", bleedHeight: "10.25", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "8.25 x 6", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "8.5", bleedHeight: "6.25", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "8.25 x 8.25", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "8.5", bleedHeight: "8.5", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "8.5 x 8.5", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "8.75", bleedHeight: "8.75", bleedMargin: "0.125", minPages: 24, maxPages: 828),
        KDPTrimSpec(trim: "8.5 x 11", marginTop: "0.75", marginBottom: "0.75", marginInner: "0.75", marginOuter: "0.5", gutter: "0.375", bleedWidth: "8.75", bleedHeight: "11.25", bleedMargin: "0.125", minPages: 24, maxPages: 828)
    ]
    
    // --- Normalizer and autofill ---
    func normalizeTrim(_ s: String) -> String {
        // Converts: 5" x 8" -> 5 x 8
        s.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces)
    }
    func kdpSpecFor(trim: String, pages: Int) -> KDPTrimSpec? {
        let normalized = normalizeTrim(trim)
        return kdpSpecs.first { $0.trim == normalized && pages >= $0.minPages && pages <= $0.maxPages }
    }
    
    var estimatedWordsPerPage: Int {
        let trim = settingsStore.settings.printTrimSize ?? "6\" x 9\""
        let fontSizeValue = Double(settingsStore.settings.fontSize ?? "11") ?? 11
        let lineSpacingValue = Double(settingsStore.settings.lineSpacing ?? "1.2") ?? 1.2

        let baseWords: Int = {
            if trim.contains("8.5") && trim.contains("11") { return 600 }
            if trim.contains("8.25") && trim.contains("11") { return 590 }
            if trim.contains("8.25") && trim.contains("10.75") { return 570 }
            if trim.contains("8.5") && trim.contains("8.5") { return 460 }
            if trim.contains("7") && trim.contains("10") { return 400 }
            if trim.contains("6.69") && trim.contains("9.61") { return 390 }
            if trim.contains("6") && trim.contains("9") { return 370 }
            if trim.contains("5.5") && trim.contains("8.5") { return 320 }
            if trim.contains("5") && trim.contains("8") { return 300 }
            return 370
        }()

        let fontSizeMod = 11.0 / fontSizeValue
        let lineSpacingMod = 1.2 / lineSpacingValue
        return max(100, Int(Double(baseWords) * fontSizeMod * lineSpacingMod))
    }

    var estimatedPages: Int {
        let totalWords = settingsStore.settings.words ?? 0
        return max(1, (totalWords + estimatedWordsPerPage - 1) / estimatedWordsPerPage)
    }
    
    func baseWords(for trim: String) -> Int {
        if trim.contains("8.5") && trim.contains("11") { return 600 }
        if trim.contains("8.25") && trim.contains("11") { return 590 }
        if trim.contains("8.25") && trim.contains("10.75") { return 570 }
        if trim.contains("8.5") && trim.contains("8.5") { return 460 }
        if trim.contains("7") && trim.contains("10") { return 400 }
        if trim.contains("6.69") && trim.contains("9.61") { return 390 }
        if trim.contains("6") && trim.contains("9") { return 370 }
        if trim.contains("5.5") && trim.contains("8.5") { return 320 }
        if trim.contains("5") && trim.contains("8") { return 300 }
        return 370
    }

        func autofillKDPFieldsIfNeeded() {
            guard settingsStore.settings.printTarget == "Amazon KDP" else { return }
            guard let trim = settingsStore.settings.printTrimSize else { return }

            let pages = estimatedPages

            if let spec = kdpSpecFor(trim: trim, pages: pages) {
                settingsStore.settings.marginTop = spec.marginTop
                settingsStore.settings.marginBottom = spec.marginBottom
                settingsStore.settings.marginInner = spec.marginInner
                settingsStore.settings.marginOuter = spec.marginOuter
                settingsStore.settings.bleedWidth = spec.bleedWidth
                settingsStore.settings.bleedHeight = spec.bleedHeight
                settingsStore.settings.bleedMargin = spec.bleedMargin
            }

            // Gutter based on page count
            settingsStore.settings.gutter = {
                switch pages {
                case 0...150: return "0.375"
                case 151...300: return "0.5"
                case 301...500: return "0.625"
                case 501...700: return "0.75"
                case 701...828: return "0.875"
                default: return "0.375"
                }
            }()
        }

    var currentTrimSizes: [String] {
        trimSizes[settingsStore.settings.printTarget ?? "Amazon KDP"] ?? ["Custom size..."]
    }

    // Bindings for all fields (unchanged)
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
                    if settingsStore.settings.printTarget == "Amazon KDP" {
                        autofillKDPFieldsIfNeeded()
                    }
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
                .onChange(of: settingsStore.settings.printTrimSize) { _ in
                    if settingsStore.settings.printTarget == "Amazon KDP" {
                        autofillKDPFieldsIfNeeded()
                    }
                }

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
                .onChange(of: settingsStore.settings.fontSize) { _ in
                    if settingsStore.settings.printTarget == "Amazon KDP" {
                        autofillKDPFieldsIfNeeded()
                    }
                }

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
                .onChange(of: settingsStore.settings.fontSize) { _ in
                    if settingsStore.settings.printTarget == "Amazon KDP" {
                        autofillKDPFieldsIfNeeded()
                    }
                }
                .onChange(of: settingsStore.settings.lineSpacing) { _ in
                    if settingsStore.settings.printTarget == "Amazon KDP" {
                        autofillKDPFieldsIfNeeded()
                    }
                }

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

                // --- Calculation helpers ---
                let trim = (settingsStore.settings.printTrimSize ?? "6\" x 9\"")
                let fontSizeValue = Double(settingsStore.settings.fontSize ?? "11") ?? 11
                let lineSpacingValue = Double(settingsStore.settings.lineSpacing ?? "1.2") ?? 1.2

                let baseWords: Int = {
                    if trim.contains("8.5") && trim.contains("11") { return 600 }
                    if trim.contains("8.25") && trim.contains("11") { return 590 }
                    if trim.contains("8.25") && trim.contains("10.75") { return 570 }
                    if trim.contains("8.5") && trim.contains("8.5") { return 460 }
                    if trim.contains("7") && trim.contains("10") { return 400 }
                    if trim.contains("6.69") && trim.contains("9.61") { return 390 }
                    if trim.contains("6") && trim.contains("9") { return 370 }
                    if trim.contains("5.5") && trim.contains("8.5") { return 320 }
                    if trim.contains("5") && trim.contains("8") { return 300 }
                    return 370
                }()
                let fontSizeMod = 11.0 / fontSizeValue
                let lineSpacingMod = 1.2 / lineSpacingValue
//                let estimatedWordsPerPage = max(100, Int(Double(baseWords) * fontSizeMod * lineSpacingMod))
                let totalWords = settingsStore.settings.words ?? 0
                let estimatedPages = max(1, (totalWords + estimatedWordsPerPage - 1) / estimatedWordsPerPage)

                
                // --- UI ---
                HStack {
                    Text("Words per page: \(estimatedWordsPerPage)")
                        .font(.subheadline)
                    Spacer()
                    Text("Est. pages: \(estimatedPages)")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

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
                .padding(.horizontal)
            }
        }
        .onAppear {
            if settingsStore.settings.printTrimSize == nil || settingsStore.settings.printTrimSize == "" {
                selectedTrimSize.wrappedValue = currentTrimSizes.first ?? ""
            }
            if settingsStore.settings.printTarget == "Amazon KDP" {
                autofillKDPFieldsIfNeeded()
            }
        }
        .onChange(of: settingsStore.settings.printTrimSize) { _ in
            autofillKDPFieldsIfNeeded()
        }
        .onChange(of: settingsStore.settings.words) { _ in
            if settingsStore.settings.printTarget == "Amazon KDP" {
                autofillKDPFieldsIfNeeded()
            }
        }
        .onChange(of: settingsStore.settings.fontSize) { _ in
            if settingsStore.settings.printTarget == "Amazon KDP" {
                autofillKDPFieldsIfNeeded()
            }
        }
        .onChange(of: settingsStore.settings.lineSpacing) { _ in
            if settingsStore.settings.printTarget == "Amazon KDP" {
                autofillKDPFieldsIfNeeded()
            }
        }
        // ALSO: autofill if total words change (for KDP)
        .onChange(of: settingsStore.settings.printTrimSize) {
            autofillKDPFieldsIfNeeded()
        }
    }
}
