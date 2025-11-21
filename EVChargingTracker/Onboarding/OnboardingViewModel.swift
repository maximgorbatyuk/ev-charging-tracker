//
//  OnboardingViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.11.2025.
//

import Foundation

class OnboardingViewModel: ObservableObject {

    var languageManager = LocalizationManager.shared
    var selectedLanguage: AppLanguage

    var pages: [OnboardingPageViewModelItem] = []
    var totalPages: Int = 0

    init() {
        languageManager = .shared
        selectedLanguage = languageManager.currentLanguage

        recreatePages()
    }

    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        recreatePages()
    }

    func getLocalizedString(_ key: String) -> String {
        return languageManager.localizedString(forKey: key)
    }

    func recreatePages() {

        pages = [
            OnboardingPageViewModelItem(
                icon: "battery.100percent.bolt",
                title: L("onboarding.track_your_chargings", language: selectedLanguage),
                description: L("onboarding.track_your_chargings__subtitle", language: selectedLanguage),
                color: .orange
            ),
            OnboardingPageViewModelItem(
                icon: "dollarsign.circle.fill",
                title: L("onboarding.monitor_costs", language: selectedLanguage),
                description: L("onboarding.monitor_costs__subtitle", language: selectedLanguage),
                color: .green
            ),
            OnboardingPageViewModelItem(
                icon: "hammer.fill",
                title: L("onboarding.plan_maintenance", language: selectedLanguage),
                description: L("onboarding.plan_maintenance__subtitle", language: selectedLanguage),
                color: .blue
            ),
            OnboardingPageViewModelItem(
                icon: "chart.line.uptrend.xyaxis",
                title: L("onboarding.view_stats", language: selectedLanguage),
                description: L("onboarding.view_stats__subtitle", language: selectedLanguage),
                color: .cyan
            ),
        ]
        totalPages = 1 + pages.count
    }
}
