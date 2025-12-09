//
//  DeveloperModeManager.swift
//  EVChargingTracker
//
//  Created on 09.12.2025.
//

import Foundation

/// Manager for developer mode that stores state in memory only (lost when app closes)
class DeveloperModeManager: ObservableObject {
    
    static let shared = DeveloperModeManager()
    
    @Published private(set) var isDeveloperModeEnabled: Bool = false
    @Published var tapCount: Int = 0
    @Published var shouldShowActivationAlert: Bool = false
    
    private let requiredTaps = 15
    
    private init() {}
    
    func handleVersionTap() {
        tapCount += 1
        
        if tapCount >= requiredTaps && !isDeveloperModeEnabled {
            enableDeveloperMode()
            tapCount = 0 // Reset counter after activation
        }
    }
    
    func enableDeveloperMode() {
        isDeveloperModeEnabled = true
        shouldShowActivationAlert = true
    }
    
    func disableDeveloperMode() {
        isDeveloperModeEnabled = false
        tapCount = 0
    }
    
    func resetTapCount() {
        tapCount = 0
    }
    
    func dismissAlert() {
        shouldShowActivationAlert = false
    }
}
