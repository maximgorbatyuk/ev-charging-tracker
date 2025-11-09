//
//  MainTabView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

import SwiftUI

struct MainTabView: SwiftUI.View {

    private var viewModel = MainTabViewModel()

    @State private var pendingMaintenanceRecords: Int = 0
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

            PlanedMaintenanceView(
                onPlannedMaintenaceRecordsUpdated: {
                    self.pendingMaintenanceRecords = viewModel.getPendingMaintenanceRecords()
                }
            )
                .tabItem {
                    Label(L("Maintenance"), systemImage: "hammer.fill")
                }
                .badge(pendingMaintenanceRecords)

            UserSettingsView()
                .tabItem {
                    Label(L("Settings"), systemImage: "gear")
                }
        }
        .id(loc.currentLanguage.rawValue)
        .onAppear {
            self.pendingMaintenanceRecords = viewModel.getPendingMaintenanceRecords()
        }
    }
}

#Preview {
    MainTabView()
}
