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
                emptySectionView(
                    icon: "wrench.and.screwdriver",
                    message: L("No maintenance records yet")
                )
                .contentShape(Rectangle())
                .onTapGesture { onNavigate(.maintenance) }
            } else {
                ForEach(viewModel.maintenancePreview) { record in
                    maintenancePreviewRow(record)
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
                emptySectionView(
                    icon: "doc.text",
                    message: L("No documents yet")
                )
                .contentShape(Rectangle())
                .onTapGesture { onNavigate(.documents) }
            } else {
                ForEach(viewModel.documentsPreview) { document in
                    documentPreviewRow(document)
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
                emptySectionView(
                    icon: "lightbulb",
                    message: L("No ideas yet")
                )
                .contentShape(Rectangle())
                .onTapGesture { onNavigate(.ideas) }
            } else {
                ForEach(viewModel.ideasPreview) { idea in
                    ideaPreviewRow(idea)
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

    // MARK: - Preview Rows

    private func maintenancePreviewRow(_ record: PlannedMaintenanceItem) -> some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let when = record.when {
                        Label(
                            when.formatted(as: "yyyy-MM-dd"),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundColor(Date() > when ? .red : .secondary)
                    }

                    if let odometer = record.odometer {
                        Label(
                            "\(odometer.formatted()) km",
                            systemImage: "speedometer"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func documentPreviewRow(_ document: CarDocument) -> some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: CarDocument.iconName(for: document.fileType))
                .font(.title3)
                .foregroundColor(CarDocument.iconColor(for: document.fileType))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(document.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func ideaPreviewRow(_ idea: Idea) -> some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundColor(.yellow)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let host = idea.hostName {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text(host)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                } else if let desc = idea.descriptionText, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private func emptySectionView(icon: String, message: String) -> some SwiftUI.View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.5))
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
}
