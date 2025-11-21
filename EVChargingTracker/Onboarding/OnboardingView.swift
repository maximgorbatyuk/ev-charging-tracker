//
//  OnboardingView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.11.2025.
//

import SwiftUI

struct OnboardingView: SwiftUI.View {

    let onOnboardingSkipped: () -> Void
    let onOnboardingCompleted: () -> Void

    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentPage = 0

    private var analytics = AnalyticsService.shared

    init(
        onOnboardingSkipped: @escaping () -> Void,
        onOnboardingCompleted: @escaping () -> Void) {
            
        self.onOnboardingSkipped = onOnboardingSkipped
        self.onOnboardingCompleted = onOnboardingCompleted
    }

    var body: some SwiftUI.View {
        ZStack {

            // Background gradient based on current page
            if currentPage == 0 {
                // Language selection page - use blue gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

            } else {
                // Content pages - use page-specific color
                let pageIndex = currentPage - 1
                if pageIndex < viewModel.pages.count {
                    LinearGradient(
                        colors: [
                            viewModel.pages[pageIndex].color.opacity(0.3),
                            viewModel.pages[pageIndex].color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
            } // end of if..else block with language
            
            VStack {
                // Skip button (only show after language selection)
                HStack {
                    Spacer()
                    if currentPage > 0 && currentPage < viewModel.totalPages - 1 {
                        Button(L("Skip")) {
                            analytics.trackEvent(
                                "onboarding_skipped_button_clicked",
                                properties: [
                                    "screen": "onboarding_screen"
                                ])

                            onOnboardingSkipped()
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }

                // Page content
                TabView(selection: $currentPage) {

                    OnboardingLanguageSelectionView(
                        onCurrentLanguageSelected: { selectedLanguage in
                            viewModel.setLanguage(selectedLanguage)
                            analytics.trackEvent(
                                "onboarding_language_changed",
                                properties: [
                                    "screen": "onboarding_screen"
                                ])
                        },
                        localizationManager: viewModel.languageManager,
                        selectedLanguage: viewModel.selectedLanguage
                    )
                    .tag(0)
                    
                    // Content pages (pages 1+)
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index + 1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicator
                PageIndicator(
                    currentPage: currentPage,
                    totalPages: viewModel.totalPages,
                    color: currentPage == 0 ? .blue : viewModel.pages[min(currentPage - 1, viewModel.pages.count - 1)].color
                )
                .padding(.bottom, 8)

                // Bottom buttons
                VStack(spacing: 16) {
                    if currentPage == 0 {
                        // Continue button on language selection
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Image(systemName: "arrow.forward")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else if currentPage == viewModel.totalPages - 1 {
                        // Get Started button on last page
                        Button(action: {
                            analytics.trackEvent(
                                "onboarding_finished",
                                properties: [
                                    "screen": "onboarding_screen"
                                ])

                            onOnboardingCompleted()
                        }) {
                            Text(L("Get started"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.pages[currentPage - 1].color)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else {
                        // Next button on other pages
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text(L("Next"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.pages[currentPage - 1].color)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            } // end of VStack

        } // end of ZStack
        .onAppear {
            analytics.trackScreen("onboarding_screen")
        }
    }
}

// Custom page indicator
struct PageIndicator: SwiftUI.View {
    let currentPage: Int
    let totalPages: Int
    let color: Color
    
    var body: some SwiftUICore.View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                if index == currentPage {
                    Capsule()
                        .fill(color)
                        .frame(width: 20, height: 8)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .animation(.spring(), value: currentPage)
    }
}
