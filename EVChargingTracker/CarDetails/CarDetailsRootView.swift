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

    @State private var showEditCarSheet = false

    let onNavigate: (CarFlowRoute) -> Void
    let onPlannedMaintenanceRecordsUpdated: () -> Void

    var body: some SwiftUI.View {
        ScrollView {
            LazyVStack(spacing: 0) {
                carInfoSection

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
                                onPlannedMaintenanceRecordsUpdated()
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
        .sheet(isPresented: $showEditCarSheet) {
            editCarSheet
        }
        .onAppear {
            analytics.trackScreen("car_details_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
    }

    // MARK: - Car Info Section

    private var carInfoSection: some SwiftUI.View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .font(.headline)
                        .foregroundColor(.green)

                    Text(L("Car mileage"))
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: { showEditCarSheet = true }) {
                    HStack(spacing: 4) {
                        Text(L("Edit"))
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            if let car = viewModel.selectedCar {
                CarInfoContent(car: car)
            } else {
                EmptySectionView(
                    icon: "car",
                    message: L("No car selected")
                )
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture { showEditCarSheet = true }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - Edit Car Sheet

    private var editCarSheet: some SwiftUI.View {
        Group {
            if let car = viewModel.selectedCar, let carId = car.id {
                EditCarView(
                    car: CarDto(
                        id: carId,
                        name: car.name,
                        selectedForTracking: car.selectedForTracking,
                        batteryCapacity: car.batteryCapacity,
                        currentMileage: car.currentMileage,
                        initialMileage: car.initialMileage,
                        expenseCurrency: car.expenseCurrency,
                        frontWheelSize: car.frontWheelSize,
                        rearWheelSize: car.rearWheelSize
                    ),
                    defaultCurrency: car.expenseCurrency,
                    defaultValueForSelectedForTracking: car.selectedForTracking,
                    hasOtherCars: viewModel.hasOtherCars(carIdToExclude: carId),
                    onSave: { updated in
                        guard let carToUpdate = viewModel.getCarById(carId) else { return }
                        carToUpdate.updateValues(
                            name: updated.name,
                            batteryCapacity: updated.batteryCapacity,
                            intialMileage: updated.initialMileage,
                            currentMileage: updated.currentMileage,
                            expenseCurrency: updated.expenseCurrency,
                            selectedForTracking: updated.selectedForTracking,
                            frontWheelSize: updated.frontWheelSize,
                            rearWheelSize: updated.rearWheelSize
                        )
                        _ = viewModel.updateCar(carToUpdate)
                        showEditCarSheet = false
                        viewModel.loadData()
                        onPlannedMaintenanceRecordsUpdated()
                    },
                    onDelete: { carToDelete in
                        guard let deleteId = carToDelete.id else { return }
                        viewModel.deleteCar(deleteId)
                        showEditCarSheet = false
                        viewModel.loadData()
                        onPlannedMaintenanceRecordsUpdated()
                    },
                    onCancel: {
                        showEditCarSheet = false
                    }
                )
            }
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
