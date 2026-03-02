//
//  CarDetailsRootView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct CarDetailsRootView: SwiftUI.View {

    @StateObject private var viewModel = CarDetailsViewModel()
    @ObservedObject private var analytics = AnalyticsService.shared

    let onNavigate: (CarFlowRoute) -> Void
    let onPlannedMaintenaceRecordsUpdated: () -> Void

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: 16) {
                maintenanceSection

                documentsSection

                ideasSection

                Spacer()
                    .frame(height: 80)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
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
            badgeCount: viewModel.pendingMaintenanceCount,
            onSeeAll: { onNavigate(.maintenance) }
        ) {
            if viewModel.maintenancePreview.isEmpty {
                sectionEmptyState(
                    icon: "wrench.and.screwdriver",
                    message: L("No maintenance records yet")
                )
            } else {
                ForEach(viewModel.maintenancePreview) { record in
                    PlannedMaintenanceItemView(record: record)
                }
            }
        }
    }

    // MARK: - Documents Section

    private var documentsSection: some SwiftUI.View {
        CarDetailsSectionView(
            title: L("Documents"),
            onSeeAll: { onNavigate(.documents) }
        ) {
            if viewModel.documentsPreview.isEmpty {
                sectionEmptyState(
                    icon: "doc.text",
                    message: L("No documents yet")
                )
            } else {
                ForEach(viewModel.documentsPreview) { document in
                    documentPreviewRow(document)
                }
            }
        }
    }

    // MARK: - Ideas Section

    private var ideasSection: some SwiftUI.View {
        CarDetailsSectionView(
            title: L("Ideas"),
            onSeeAll: { onNavigate(.ideas) }
        ) {
            if viewModel.ideasPreview.isEmpty {
                sectionEmptyState(
                    icon: "lightbulb",
                    message: L("No ideas yet")
                )
            } else {
                ForEach(viewModel.ideasPreview) { idea in
                    ideaPreviewRow(idea)
                }
            }
        }
    }

    // MARK: - Preview Rows

    private func documentPreviewRow(_ document: CarDocument) -> some SwiftUI.View {
        HStack(spacing: 10) {
            Image(systemName: CarDocument.iconName(for: document.fileType))
                .font(.body)
                .foregroundColor(CarDocument.iconColor(for: document.fileType))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.displayTitle)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(document.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func ideaPreviewRow(_ idea: Idea) -> some SwiftUI.View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.body)
                .foregroundColor(.yellow)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(idea.title)
                    .font(.subheadline)
                    .lineLimit(1)

                if let host = idea.hostName {
                    Text(host)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func sectionEmptyState(icon: String, message: String) -> some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.gray.opacity(0.5))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }
}
