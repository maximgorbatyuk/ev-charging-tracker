//
//  UserSettings.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

// Define keys used to store user settings in the DB
enum UserSettingKey: String {
    case currency = "currency"
    case fontFamily = "font_family"
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

/// Whether the per-distance cost figures on the Stats screen are shown per a
/// single unit (1 km / 1 mi) or per a hundred units (100 km / 100 mi). This is
/// a display preference only; the stored cost-per-distance value is unchanged.
enum DistanceCostBasis: String, CaseIterable, Codable {
    case perUnit = "per_unit"
    case perHundredUnits = "per_hundred_units"

    var displayName: String {
        switch self {
        case .perUnit: return L("distance.cost.basis.per_unit")
        case .perHundredUnits: return L("distance.cost.basis.per_hundred")
        }
    }

    /// Factor applied to the per-single-unit value at the display boundary.
    var multiplier: Double {
        switch self {
        case .perUnit: return 1
        case .perHundredUnits: return 100
        }
    }
}

/// User-selectable font family. `.system` always uses the iOS system font;
/// `.jetBrainsMono` uses bundled JetBrains Mono (falls back to system for
/// unsupported scripts — see `AppFont.supports(_:)`).
enum AppFontFamily: String, CaseIterable, Codable {
    case system = "system"
    case jetBrainsMono = "jetbrains_mono"

    var displayName: String {
        switch self {
        case .system: return L("font.family.system")
        case .jetBrainsMono: return L("font.family.jetbrains_mono")
        }
    }
}
