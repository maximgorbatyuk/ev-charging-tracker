//
//  OnboardingLanguageSelectionView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.11.2025.
//

import SwiftUI

struct OnboardingLanguageSelectionView: SwiftUICore.View {

    let onCurrentLanguageSelected: (_ selectedLanguage: AppLanguage) -> Void
    
    @ObservedObject var localizationManager: LocalizationManager = .shared
    @ObservedObject var analytics: AnalyticsService = .shared

    @State var selectedLanguage: AppLanguage

    var body: some SwiftUICore.View {
        VStack(spacing: 20) {
            Spacer()

            Image("BackgroundImage")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130) // Adjust size as needed
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)

            VStack(spacing: 8) {
                Text(L("Welcome to"))
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("EV Charge Tracker")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
            }

            Text(L("Select your language"))
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 5)

            // Language options
            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    LanguageButton(
                        language: language,
                        isSelected: selectedLanguage == language
                    ) {
                        withAnimation(.spring()) {
                            selectedLanguage = language
                            localizationManager.setLanguage(language)
                            onCurrentLanguageSelected(language)

                            analytics.trackEvent("language_selected", properties: [
                                "language": language.rawValue,
                                "screen": "onboarding_language_selection"
                            ])
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    } // end of body
}

struct LanguageButton: SwiftUICore.View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some SwiftUICore.View {
        Button(action: action) {
            HStack {
                Text(language.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
