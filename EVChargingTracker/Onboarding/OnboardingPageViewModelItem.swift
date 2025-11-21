//
//  OnboardingPageViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.11.2025.
//
import Foundation
import SwiftUICore

struct OnboardingPageViewModelItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}
