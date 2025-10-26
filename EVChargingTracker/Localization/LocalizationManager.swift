import Foundation
import Combine

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage

    private init() {
        // Read saved language from DB if available, otherwise default to en
        if let repo = DatabaseManager.shared.userSettingsRepository {
            self.currentLanguage = repo.fetchLanguage()
        } else {
            self.currentLanguage = .en
        }
    }

    var locale: Locale {
        Locale(identifier: currentLanguage.rawValue)
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        // Persisting to DB is handled by the viewModel (caller).
        // Send a notification so views can react if they observe this object.
        // Observers will see `currentLanguage` change via @Published.
    }

    // Return localized string for a given key using the language-specific bundle
    func localizedString(forKey key: String) -> String {
        // Try to load language bundle from main bundle's lproj folders
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        // fallback to main bundle / key itself
        return Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }
}

// Global helper to call from views
func L(_ key: String) -> String {
    return LocalizationManager.shared.localizedString(forKey: key)
}
