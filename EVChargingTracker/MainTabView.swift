//
//  MainTabView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

import SwiftUI

struct MainTabView: SwiftUI.View {
    @ObservedObject private var loc = LocalizationManager.shared

    var body: some SwiftUI.View {
        TabView {
            ChargingSessionsView()
                .tabItem {
                    Label(L("Stats"), systemImage: "bolt.car.fill")
                }
            
            ExpensesView()
                .tabItem {
                    Label(L("Expenses"), systemImage: "dollarsign.circle")
                }

            UserSettingsView()
                .tabItem {
                    Label(L("Settings"), systemImage: "person.circle.fill")
                }
            
            AboutView()
                .tabItem {
                    Label(L("About"), systemImage: "info.circle")
                }
        }
        .id(loc.currentLanguage.rawValue)
    }
}

#Preview {
    MainTabView()
}
