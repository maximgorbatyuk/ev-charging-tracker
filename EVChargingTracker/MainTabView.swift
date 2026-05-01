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
                    .tint(nil)
                    .tag(0)

                ExpensesView()
                    .tabItem {
                        Label(L("Expenses"), systemImage: "dollarsign.circle")
                    }
                    .tint(nil)
                    .tag(1)

                CarDetailsView(
                    onPlannedMaintenanceRecordsUpdated: {
                        self.pendingMaintenanceRecords = viewModel.getPendingMaintenanceRecords()
                    }
                )
                    .tag(2)
                    .tabItem {
                        Label(L("Car"), systemImage: "car.fill")
                    }
                    .tint(nil)
                    .badge(pendingMaintenanceRecords)

                UserSettingsView(showAppUpdateButton: showAppVersionBadge)
                    .tabItem {
                        Label(L("Settings"), systemImage: "gear")
                    }
                    .tag(3)
                    .tint(nil)
                    .badge(showAppVersionBadge ? "New!" : nil)
            }
            .tint(AppTheme.tabMenuTintColor(for: colorScheme))
            .id(loc.currentLanguage.rawValue)
            .onAppear {
                self.pendingMaintenanceRecords = viewModel.getPendingMaintenanceRecords()

                Task {
                    let appVersionCheckResult = await viewModel.checkAppVersion()
                    showAppVersionBadge = appVersionCheckResult ?? false
                }

                // First-launch trigger for nav-bar font appearance: the
                // UIAppearance proxy doesn't reliably propagate
                // scrollEdgeAppearance to bars created by NavigationView,
                // so force-write onto the bars now that this view (and
                // therefore the underlying UINavigationControllers) has
                // mounted. Defer one runloop tick to let SwiftUI finish
                // attaching the bars.
                DispatchQueue.main.async {
                    AppFontAppearance.shared.refreshLiveBars()
                }
            }
        }
    }

}

#Preview {
    MainTabView()
}
