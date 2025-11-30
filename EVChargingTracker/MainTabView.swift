//
//  MainTabView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

import SwiftUI

struct MainTabView: SwiftUI.View {

    private var viewModel = MainTabViewModel(
        db: DatabaseManager.shared,
        appVersionChecker: AppVersionChecker(
            environment: EnvironmentService.shared
        )
    )

    @State private var pendingMaintenanceRecords: Int = 0
    @State private var showAppVersionBadge = false

    @ObservedObject private var loc = LocalizationManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUI.View {
        ZStack {
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

                UserSettingsView(showAppUpdateButton: showAppVersionBadge)
                    .tabItem {
                        Label(L("Settings"), systemImage: "gear")
                    }
                    .badge(showAppVersionBadge ? "New!" : nil)
            }
            .id(loc.currentLanguage.rawValue)
            .onAppear {
                self.pendingMaintenanceRecords = viewModel.getPendingMaintenanceRecords()

                Task {
                    let appVersionCheckResult = await viewModel.checkAppVersion()
                    showAppVersionBadge = appVersionCheckResult ?? false
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
