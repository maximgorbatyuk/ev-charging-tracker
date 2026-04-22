//
//  AppFontFamilyManager.swift
//  EVChargingTracker
//
//  Singleton owning the user-selected font family, backed by the
//  `user_settings` SQLite table so the preference rides along with
//  iCloud backup / import / export.
//

import Foundation

final class AppFontFamilyManager: ObservableObject {
    static let shared = AppFontFamilyManager()

    @Published private(set) var currentFamily: AppFontFamily

    private init() {
        self.currentFamily = DatabaseManager.shared.userSettingsRepository?.fetchFontFamily() ?? .jetBrainsMono
    }

    /// Persists the new family to the DB and publishes the change so
    /// SwiftUI views + `AppFontAppearance` react immediately.
    func setFamily(_ family: AppFontFamily) {
        guard family != currentFamily else {
            return
        }

        currentFamily = family
        _ = DatabaseManager.shared.userSettingsRepository?.upsertFontFamily(family)
    }
}
