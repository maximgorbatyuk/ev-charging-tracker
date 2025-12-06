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
    @State private var selectedTab: Int = 0

    var body: some SwiftUI.View {
        ZStack {
            TabView(selection: $selectedTab) {
                ChargingSessionsView()
                    .tabItem {
                        Label(L("Stats"), systemImage: "bolt.car.fill")
                    }
                    .tint(Color.accentColor)
                    .tag(0)

                ExpensesView()
                    .tabItem {
                        Label(L("Expenses"), systemImage: "dollarsign.circle")
                    }
                    .tint(Color.accentColor)
                    .tag(1)

                PlanedMaintenanceView(
                    onPlannedMaintenaceRecordsUpdated: {
                        self.pendingMaintenanceRecords = viewModel.getPendingMaintenanceRecords()
                    }
                )
                    .tag(2)
                    .tabItem {
                        Label(L("Maintenance"), systemImage: "hammer.fill")
                    }
                    .tint(Color.accentColor)
                    .badge(pendingMaintenanceRecords)

                UserSettingsView(showAppUpdateButton: showAppVersionBadge)
                    .tabItem {
                        Label(L("Settings"), systemImage: "gear")
                    }
                    .tag(3)
                    .tint(Color.accentColor)
                    .badge(showAppVersionBadge ? "New!" : nil)
            }
            .tint(getTabViewColor())
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
    
    private func getTabViewColor() -> Color {
        switch selectedTab {
            case 0:
                return Color.orange
            case 1:
                return Color.green
            case 2:
                return Color.cyan
            case 3:
                return Color.blue
            default:
            return Color.primary
        }
    }
}

#Preview {
    MainTabView()
}
