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
    case ru = "ru"

    var displayName: String {
        switch self {
        case .en: return "🇬🇧 English"
        case .ru: return "🇷🇺 Русский"
        }
    }
}

// Add key constant for language
extension UserSettingKey {
    static let language = UserSettingKey(rawValue: "language")!
}
