//
//  UserSettings.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

// Define keys used to store user settings in the DB
enum UserSettingKey: String {
    case currency = "currency"
}

// New: supported app languages
enum AppLanguage: String, CaseIterable, Codable {
    case en = "en"
    case de = "de"
    case ru = "ru"
    case kk = "kk"
    case tr = "tr"
    case uk = "uk"
    case zhHans = "zh-Hans"

    var displayName: String {
        switch self {
            case .en: return "🇬🇧 English"
            case .de: return "🇩🇪 Deutsch"
            case .ru: return "🇷🇺 Русский"
            case .kk: return "🇰🇿 Қазақша"
            case .tr: return "🇹🇷 Türkçe"
            case .uk: return "🇺🇦 Українська"
            case .zhHans: return "🇨🇳 简体中文"
        }
    }
}

// Add key constant for language
extension UserSettingKey {
    static let language = UserSettingKey(rawValue: "language")!
}

/// Appearance mode for the app (light, dark, or system)
enum AppearanceMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return L("System")
        case .light: return L("Light")
        case .dark: return L("Dark")
        }
    }
}
