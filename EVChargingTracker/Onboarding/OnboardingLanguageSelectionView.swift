//
//  OnboardingLanguageSelectionView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.11.2025.
//

import SwiftUI

struct OnboardingLanguageSelectionView: SwiftUICore.View {

    @ObservedObject var localizationManager: LocalizationManager = .shared
    @SwiftUICore.Binding var selectedLanguage: AppLanguage

    var body: some SwiftUICore.View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon or logo
            Image(systemName: "bolt.car.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
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
                .padding(.top, 20)

            // Language options
            VStack(spacing: 16) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    LanguageButton(
                        language: language,
                        isSelected: selectedLanguage == language
                    ) {
                        withAnimation(.spring()) {
                            selectedLanguage = language
                            localizationManager.setLanguage(language)
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
                Text(language.flag)
                    .font(.largeTitle)
                
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
