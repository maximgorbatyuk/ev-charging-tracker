import Foundation
import Combine

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage

    /// Bundle containing `.lproj` localization resources.
    /// In the main app this is `Bundle.main`.
    /// In an app extension (.appex) this resolves to the containing app bundle.
    private static let localizationBundle: Bundle = {
        let main = Bundle.main
        if main.bundleURL.pathExtension == "appex" {
            // .../EVChargingTracker.app/PlugIns/ShareExtension.appex → go up twice
            let appURL = main.bundleURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            if let appBundle = Bundle(url: appURL) {
                return appBundle
            }
        }
        return main
    }()

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

    func setLanguage(_ language: AppLanguage) throws {
        guard language != currentLanguage else { return }
        currentLanguage = language

        let success = DatabaseManager.shared.userSettingsRepository?.upsertLanguage(language.rawValue) ?? false
        if !success {
            throw RuntimeError("Failed to save selected language to DB")
        }
    }

    func localizedString(forKey key: String) -> String {
        return localizedString(forKey: key, language: currentLanguage)
    }

    func localizedString(forKey key: String, language: AppLanguage) -> String {
        let base = Self.localizationBundle

        // Try to load language bundle from lproj folders
        if let path = base.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }

        // fallback to base bundle / key itself
        return base.localizedString(forKey: key, value: key, table: nil)
    }
}

// Global helper to call from views
func L(_ key: String) -> String {
    return LocalizationManager.shared.localizedString(forKey: key)
}

func L(_ key: String, language: AppLanguage) -> String {
    return LocalizationManager.shared.localizedString(forKey: key, language: language)
}
