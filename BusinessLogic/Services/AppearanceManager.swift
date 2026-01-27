//
//  AppearanceManager.swift
//  EVChargingTracker
//
//  Created by Claude on 27.01.2026.
//

import SwiftUI

/// Manages the app's appearance mode (light, dark, or system)
final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    private static let appearanceModeKey = "appearance_mode"

    @Published var currentMode: AppearanceMode

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.appearanceModeKey),
           let mode = AppearanceMode(rawValue: stored)
        {
            self.currentMode = mode
        } else {
            self.currentMode = .system
        }
    }

    /// Returns the `ColorScheme` based on the current mode, or `nil` for system default
    var colorScheme: ColorScheme? {
        switch currentMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    /// Updates the appearance mode and persists it to UserDefaults
    func setMode(_ mode: AppearanceMode) {
        guard mode != currentMode else {
            return
        }

        currentMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.appearanceModeKey)
    }
}
