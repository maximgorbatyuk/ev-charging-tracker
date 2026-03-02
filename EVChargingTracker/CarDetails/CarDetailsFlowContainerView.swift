//
//  CarDetailsFlowContainerView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

enum CarFlowRoute: Hashable {
    case maintenance
    case documents
    case ideas
}

struct CarDetailsFlowContainerView: SwiftUI.View {

    let onPlannedMaintenanceRecordsUpdated: () -> Void

    @State private var path: [CarFlowRoute] = []
    @State private var showCreateChooser = false
    @State private var triggerAddMaintenance = false
    @State private var triggerAddIdea = false
    @State private var triggerAddDocument = false
    @State private var pendingAddAction: CarFlowRoute?

    var body: some SwiftUI.View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack(path: $path) {
                CarDetailsRootView(
                    onNavigate: { route in
                        path.append(route)
                    },
                    onPlannedMaintenanceRecordsUpdated: onPlannedMaintenanceRecordsUpdated
                )
                .navigationDestination(for: CarFlowRoute.self) { route in
                    switch route {
                    case .maintenance:
                        PlanedMaintenanceView(
                            embedded: true,
                            triggerAdd: $triggerAddMaintenance,
                            onPlannedMaintenanceRecordsUpdated: onPlannedMaintenanceRecordsUpdated
                        )
                        .onAppear { consumePendingAction(.maintenance) }
                    case .documents:
                        DocumentsListView(triggerAdd: $triggerAddDocument)
                            .onAppear { consumePendingAction(.documents) }
                    case .ideas:
                        IdeasListView(triggerAdd: $triggerAddIdea)
                            .onAppear { consumePendingAction(.ideas) }
                    }
                }
            }

            floatingAddButton
        }
        .sheet(isPresented: $showCreateChooser, onDismiss: handleCreateChooserDismiss) {
            CarQuickAddSheet { option in
                pendingAddAction = option.route
            }
        }
    }

    private func consumePendingAction(_ route: CarFlowRoute) {
        guard pendingAddAction == route else { return }
        pendingAddAction = nil
        switch route {
        case .maintenance:
            triggerAddMaintenance = true
        case .documents:
            triggerAddDocument = true
        case .ideas:
            triggerAddIdea = true
        }
    }

    private func handleCreateChooserDismiss() {
        guard let route = pendingAddAction else { return }

        path.append(route)
    }

    private var floatingAddButton: some SwiftUI.View {
        Button(action: {
            handleFabTap()
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private func handleFabTap() {
        guard let currentRoute = path.last else {
            showCreateChooser = true
            return
        }

        switch currentRoute {
        case .maintenance:
            triggerAddMaintenance = true
        case .documents:
            triggerAddDocument = true
        case .ideas:
            triggerAddIdea = true
        }
    }
}
