import Foundation
import AppKit

struct Settings: Codable, Equatable {
    // book properties
    var title: String?
    var author: String?
    var images: [String]?
    var words: Int?
    
    // epub
    var cover: String?
    var style: String?
    var fonts: [String]?
    var start: String? // start page
    var buildPath: String?
    var files: [String]?

    // Security-scoped bookmarks
    var coverBookmark: Data?
    var styleBookmark: Data?
    var fontBookmarks: [Data]?
    var imageBookmarks: [Data]?
    
    // print properties
    var printTarget: String?
    var printTrimSize: String?
    var printFont: String?
    var marginTop: String?
    var marginBottom: String?
    var marginInner: String?
    var marginOuter: String?
    var gutter: String?
    var fontSize: String?
    var lineSpacing: String?
    var bleedWidth: String?
    var bleedHeight: String?
    var bleedMargin: String?
    var ebookCoverImage: String?
    var ebookStyle: String?
    
    // New (LaTeX-ish) fields
    var letterSpacing: String?       // e.g. "0.02em" or nil
    var wordSpacing: String?         // e.g. "0.1em"
    var paragraphIndent: String?     // e.g. "1.2em"
    var paragraphSkip: String?       // e.g. "0.5em"
    var justifyText: Bool?           // true/false
    var removeSpaceBetwenHyphens: Bool?             // true/false
    var pageNumberStyle: String?     // "arabic", "roman", "none"
    var sectionSpacing: String?      // e.g. "2em"
    var printParagraphBreakSeparator: String? // e.g. * * *

//    var headerContent: String?       // e.g. "Book Title"
//    var footerContent: String?       // e.g. "Page \thepage"

}

class SettingsStore: ObservableObject {
    // Resolve security‑scoped bookmark into a usable URL
    func resolveBookmark(_ data: Data) -> URL? {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data,
                               options: [.withSecurityScope],
                               relativeTo: nil,
                               bookmarkDataIsStale: &isStale)
            _ = url.startAccessingSecurityScopedResource()
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }
    @Published var settings: Settings = Settings()
    
    private(set) var currentFolder: URL?      // The folder we're working in
    
    // Computed property for the current settings file path
    private var settingsURL: URL? {
        currentFolder?.appendingPathComponent(".publish.json")
    }
    
    // Load settings from a specific folder
    func load(from folder: URL) {
        self.currentFolder = folder     // <-- Always set currentFolder
        let fileURL = folder.appendingPathComponent(".publish.json")
        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode(Settings.self, from: data) {
            self.settings = loaded
        } else {
            self.settings = Settings()
        }
    }
    
    // Save settings to last loaded folder, if any
    func save() throws {
        guard let url = settingsURL else { return }
        let data = try JSONEncoder().encode(settings)
        try data.write(to: url)
    }
}
