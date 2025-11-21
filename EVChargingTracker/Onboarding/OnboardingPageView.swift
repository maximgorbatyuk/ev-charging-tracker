//
//  OnboardingPageView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.11.2025.
//

import SwiftUI

struct OnboardingPageView: SwiftUICore.View {
    let page: OnboardingPageViewModelItem

    var body: some SwiftUICore.View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundColor(page.color)
                .symbolEffect(.bounce, options: .repeating)

            Text(page.title)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding()
    }
}
