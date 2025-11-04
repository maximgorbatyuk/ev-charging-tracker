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

            PlanedMaintenanceView()
                .tabItem {
                    Label(L("Maintenance"), systemImage: "info.circle")
                }
            
            UserSettingsView()
                .tabItem {
                    Label(L("Settings"), systemImage: "person.circle.fill")
                }
        }
        .id(loc.currentLanguage.rawValue)
    }
}

#Preview {
    MainTabView()
}
