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
    
    private var languageManager = LocalizationManager.shared

    @State private var selectedLanguage: AppLanguage
    @State private var currentPage: Int
    private var pages: [OnboardingPageViewModelItem]
    private var totalPages: Int
    
    init(
        onOnboardingSkipped: @escaping () -> Void,
        onOnboardingCompleted: @escaping () -> Void) {
            
        self.onOnboardingSkipped = onOnboardingSkipped
        self.onOnboardingCompleted = onOnboardingCompleted

        languageManager = LocalizationManager.shared
        selectedLanguage = .en
        currentPage = 0
        pages = [
            OnboardingPageViewModelItem(
                icon: "battery.100percent.bolt",
                title: L("onboarding.track_your_chargings"),
                description: L("onboarding.track_your_chargings__subtitle"),
                color: .orange
            ),
            OnboardingPageViewModelItem(
                icon: "dollarsign.circle.fill",
                title: L("onboarding.monitor_costs"),
                description: L("onboarding.monitor_costs__subtitle"),
                color: .green
            ),
            OnboardingPageViewModelItem(
                icon: "hammer.fill",
                title: L("onboarding.plan_maintenance"),
                description: L("onboarding.plan_maintenance__subtitle"),
                color: .blue
            ),
            OnboardingPageViewModelItem(
                icon: "chart.line.uptrend.xyaxis",
                title: L("onboarding.view_stats"),
                description: L("onboarding.view_stats__subtitle"),
                color: .cyan
            ),
        ]
        totalPages = 1 + pages.count
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
                if pageIndex < pages.count {
                    LinearGradient(
                        colors: [
                            pages[pageIndex].color.opacity(0.3),
                            pages[pageIndex].color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
            } // end of if..else bock with language
            
            VStack {
                // Skip button (only show after language selection)
                HStack {
                    Spacer()
                    if currentPage > 0 && currentPage < totalPages - 1 {
                        Button(L("Skip", language: selectedLanguage)) {
                            onOnboardingSkipped()
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    // Language selection page (page 0)
                    OnboardingLanguageSelectionView(
                        localizationManager: languageManager,
                        selectedLanguage: $selectedLanguage
                    )
                    .tag(0)
                    
                    // Content pages (pages 1+)
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index + 1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator
                PageIndicator(
                    currentPage: currentPage,
                    totalPages: totalPages,
                    color: currentPage == 0 ? .blue : pages[min(currentPage - 1, pages.count - 1)].color
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
                            Text(L("Continue", language: selectedLanguage))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else if currentPage == totalPages - 1 {
                        // Get Started button on last page
                        Button(action: {
                            onOnboardingCompleted()
                        }) {
                            Text(L("Get started", language: selectedLanguage))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(pages[currentPage - 1].color)
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
                            Text(L("Next", language: selectedLanguage))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(pages[currentPage - 1].color)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            } // end of VStack

        } // end of ZStack
        .onAppear {
            selectedLanguage = languageManager.currentLanguage
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
