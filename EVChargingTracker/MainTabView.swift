//
//  MainTabView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

import SwiftUI

struct MainTabView: SwiftUI.View {

    private var viewModel = MainTabViewModel()
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
                    Label(L("Maintenance"), systemImage: "hammer.fill")
                }
                .badge(viewModel.getPendingMaintenanceRecords()!)

            UserSettingsView()
                .tabItem {
                    Label(L("Settings"), systemImage: "gear")
                }
        }
        .id(loc.currentLanguage.rawValue)
    }
}

#Preview {
    MainTabView()
}
