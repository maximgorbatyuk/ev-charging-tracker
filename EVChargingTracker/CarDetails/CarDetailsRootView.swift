//
//  CarDetailsRootView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct CarDetailsRootView: SwiftUI.View {

    @StateObject private var viewModel = CarDetailsViewModel()
    private let analytics = AnalyticsService.shared

    let onNavigate: (CarFlowRoute) -> Void
    let onPlannedMaintenaceRecordsUpdated: () -> Void

    var body: some SwiftUI.View {
        ScrollView {
            LazyVStack(spacing: 0) {
                maintenanceSection

                documentsSection

                ideasSection

                Spacer()
                    .frame(height: 80)
            }
        }
        .background(Color(.systemGray6))
        .navigationTitle(viewModel.selectedCar?.name ?? L("Car details"))
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            if viewModel.hasMultipleCars {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(viewModel.allCars, id: \.id) { car in
                            Button {
                                viewModel.selectCar(car)
                                onPlannedMaintenaceRecordsUpdated()
                            } label: {
                                if car.id == viewModel.selectedCar?.id {
                                    Label(car.name, systemImage: "checkmark")
                                } else {
                                    Text(car.name)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "car.2.fill")
                    }
                }
            }
        }
        .onAppear {
            analytics.trackScreen("car_details_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
    }

    // MARK: - Maintenance Section

    private var maintenanceSection: some SwiftUI.View {
        CarDetailsSectionView(
            title: L("Maintenance"),
            iconName: "wrench.and.screwdriver.fill",
            iconColor: .blue,
            itemCount: viewModel.totalMaintenanceCount,
            badgeCount: viewModel.pendingMaintenanceCount,
            onSeeAll: { onNavigate(.maintenance) }
        ) {
            if viewModel.maintenancePreview.isEmpty {
                EmptySectionView(
                    icon: "wrench.and.screwdriver",
                    message: L("No maintenance records yet")
                )
                .contentShape(Rectangle())
                .onTapGesture { onNavigate(.maintenance) }
            } else {
                ForEach(viewModel.maintenancePreview) { record in
                    MaintenancePreviewRow(record: record)
                        .contentShape(Rectangle())
                        .onTapGesture { onNavigate(.maintenance) }
                    if record.id != viewModel.maintenancePreview.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - Documents Section

    private var documentsSection: some SwiftUI.View {
        CarDetailsSectionView(
            title: L("Documents"),
            iconName: "doc.fill",
            iconColor: .orange,
            itemCount: viewModel.documentsPreview.count,
            onSeeAll: { onNavigate(.documents) }
        ) {
            if viewModel.documentsPreview.isEmpty {
                EmptySectionView(
                    icon: "doc.text",
                    message: L("No documents yet")
                )
                .contentShape(Rectangle())
                .onTapGesture { onNavigate(.documents) }
            } else {
                ForEach(viewModel.documentsPreview) { document in
                    DocumentPreviewRow(document: document)
                        .contentShape(Rectangle())
                        .onTapGesture { onNavigate(.documents) }
                    if document.id != viewModel.documentsPreview.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - Ideas Section

    private var ideasSection: some SwiftUI.View {
        CarDetailsSectionView(
            title: L("Ideas"),
            iconName: "lightbulb.fill",
            iconColor: .yellow,
            itemCount: viewModel.ideasPreview.count,
            onSeeAll: { onNavigate(.ideas) }
        ) {
            if viewModel.ideasPreview.isEmpty {
                EmptySectionView(
                    icon: "lightbulb",
                    message: L("No ideas yet")
                )
                .contentShape(Rectangle())
                .onTapGesture { onNavigate(.ideas) }
            } else {
                ForEach(viewModel.ideasPreview) { idea in
                    IdeaPreviewRow(idea: idea)
                        .contentShape(Rectangle())
                        .onTapGesture { onNavigate(.ideas) }
                    if idea.id != viewModel.ideasPreview.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

}
