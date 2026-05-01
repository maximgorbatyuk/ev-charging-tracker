//
//  AppFontFamilyManager.swift
//  EVChargingTracker
//
//  Singleton owning the user-selected font family. SQLite `user_settings`
//  is the source of truth (so the value rides iCloud backup / import /
//  export). The same value is mirrored into `UserDefaults.standard` so
//  the launch screen — which must stay DB-free per CLAUDE.md — can render
//  in the chosen font on the first frame.
//

import Foundation

final class AppFontFamilyManager: ObservableObject {
    static let shared = AppFontFamilyManager()

    /// UserDefaults key for the launch-screen fast-path read. Kept in sync
    /// with the DB on init, every `setFamily(_:)`, and after backup import.
    static let userDefaultsKey = "app_font_family"

    @Published private(set) var currentFamily: AppFontFamily

    private init() {
        let stored = DatabaseManager.shared.userSettingsRepository?.fetchFontFamily() ?? .jetBrainsMono
        self.currentFamily = stored
        Self.writeUserDefaults(stored)
    }

    /// Persists the new family to the DB, mirrors to UserDefaults, and
    /// publishes the change so SwiftUI views + `AppFontAppearance` react.
    func setFamily(_ family: AppFontFamily) {
        guard family != currentFamily else {
            return
        }

        currentFamily = family
        _ = DatabaseManager.shared.userSettingsRepository?.upsertFontFamily(family)
        Self.writeUserDefaults(family)
    }

    /// Synchronous, DB-free read for paths that run before DatabaseManager
    /// is guaranteed warm — currently the launch screen. Falls back to
    /// `.jetBrainsMono` (the default) when no value has been stored yet.
    static func bootstrapFamily() -> AppFontFamily {
        guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
              let family = AppFontFamily(rawValue: raw) else {
            return .jetBrainsMono
        }
        return family
    }

    /// Re-reads the DB and refreshes both the published value and the
    /// UserDefaults mirror. Call after a backup import so the next launch
    /// screen reflects the restored choice.
    func reloadFromStorage() {
        let stored = DatabaseManager.shared.userSettingsRepository?.fetchFontFamily() ?? .jetBrainsMono
        Self.writeUserDefaults(stored)
        guard stored != currentFamily else { return }
        currentFamily = stored
    }

    private static func writeUserDefaults(_ family: AppFontFamily) {
        UserDefaults.standard.set(family.rawValue, forKey: userDefaultsKey)
    }
}
