//
//  AppTheme.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 02.03.2026.
//

import SwiftUI

enum AppTheme {
    static func tabMenuTintColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? .orange
            : Color(red: 0.85, green: 0.45, blue: 0.0)
    }
}
