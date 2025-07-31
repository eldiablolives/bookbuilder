import Foundation

struct Settings: Codable, Equatable {
    // Print settings (optional)
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
    var words: Int?

    // eBook settings (example)
    var ebookCoverImage: String?
    var ebookStyle: String?
    // Add more as needed!

    // Other app-wide or project-wide settings...
}

class SettingsStore: ObservableObject {
    @Published var settings: Settings = Settings()
    
    // MARK: - Persistence

    private static var settingsURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("mkepub-settings.json")
    }
    
    func save() throws {
        let data = try JSONEncoder().encode(settings)
        try data.write(to: Self.settingsURL)
    }
    
    func load() {
        guard let data = try? Data(contentsOf: Self.settingsURL),
              let loaded = try? JSONDecoder().decode(Settings.self, from: data)
        else { return }
        settings = loaded
    }
}
