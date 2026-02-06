//
//  PlanedMaintenanceView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

import Foundation
import SwiftUI

struct PlanedMaintenanceView: SwiftUICore.View {

    let onPlannedMaintenaceRecordsUpdated: () -> Void

    @StateObject private var viewModel = PlanedMaintenanceViewModel(
        notifications: NotificationManager.shared,
        db: DatabaseManager.shared)

    @State private var showingAddMaintenanceRecord = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var recordToDelete: PlannedMaintenanceItem? = nil
    @State private var recordToEdit: PlannedMaintenanceItem? = nil
    @State private var recordToMarkAsDone: PlannedMaintenanceItem? = nil
    @State private var recordToShowDetails: PlannedMaintenanceItem? = nil
    @State private var recordToDuplicate: PlannedMaintenanceItem? = nil

    @ObservedObject private var analytics = AnalyticsService.shared

    init(onPlannedMaintenaceRecordsUpdated: @escaping () -> Void) {
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
        self.onPlannedMaintenaceRecordsUpdated = onPlannedMaintenaceRecordsUpdated
    }

    var body: some SwiftUICore.View {
        ZStack(alignment: .bottomTrailing) {
            NavigationView {
                mainContent
                .navigationTitle(L("Planned maintenance"))
                .navigationBarTitleDisplayMode(.automatic)
                .onAppear {
                    analytics.trackScreen("planned_maintenance_screen")
                    loadData()
                }
                .refreshable {
                    loadData()
                }
                .alert(isPresented: $showingDeleteConfirmation) {
                    deleteConfirmationAlert()
                }
                .sheet(isPresented: $showingAddMaintenanceRecord) {
                    let selectedCar = viewModel.selectedCarForExpenses!
                    AddMaintenanceRecordView(
                        selectedCar: selectedCar,
                        onAdd: { newRecord in
                            analytics.trackEvent("maintenance_record_added", properties: [
                                "screen": "planned_maintenance_screen"
                            ])

                            viewModel.addNewMaintenanceRecord(newRecord: newRecord)

                            loadData()
                            onPlannedMaintenaceRecordsUpdated()
                        }
                    )
                }
                .sheet(item: $recordToEdit) { record in
                    if let selectedCar = viewModel.selectedCarForExpenses {
                        AddMaintenanceRecordView(
                            selectedCar: selectedCar,
                            existingRecord: record,
                            onAdd: { _ in },
                            onUpdate: { updatedRecord in
                                analytics.trackEvent("maintenance_record_updated", properties: [
                                    "screen": "planned_maintenance_screen"
                                ])

                                viewModel.updateMaintenanceRecord(updatedRecord)

                                loadData()
                                onPlannedMaintenaceRecordsUpdated()
                            }
                        )
                    }
                }
                .sheet(item: $recordToMarkAsDone) { record in
                    if let selectedCar = viewModel.selectedCarForExpenses {
                        AddExpenseView(
                            defaultExpenseType: .maintenance,
                            defaultCurrency: selectedCar.expenseCurrency,
                            selectedCar: selectedCar,
                            allCars: viewModel.getAllCars(),
                            prefilledTitle: record.name,
                            prefilledNotes: record.notes,
                            onAdd: { expenseResult in
                                analytics.trackEvent("expense_added_from_maintenance", properties: [
                                    "screen": "planned_maintenance_screen"
                                ])

                                viewModel.markMaintenanceAsDone(record, expenseResult: expenseResult)

                                loadData()
                                onPlannedMaintenaceRecordsUpdated()
                            }
                        )
                    }
                }
                .sheet(item: $recordToShowDetails) { record in
                    if let selectedCar = viewModel.selectedCarForExpenses {
                        PlannedMaintenanceDetailsView(
                            record: record,
                            selectedCar: selectedCar,
                            onMarkAsDone: { rec in
                                recordToShowDetails = nil
                                recordToMarkAsDone = rec
                            },
                            onEdit: { rec in
                                recordToEdit = rec
                            },
                            onDelete: { rec in
                                viewModel.deleteMaintenanceRecord(rec)
                                loadData()
                                onPlannedMaintenaceRecordsUpdated()
                            },
                            onDuplicate: { rec in
                                recordToDuplicate = rec
                            }
                        )
                    }
                }
                .sheet(item: $recordToDuplicate) { record in
                    if let selectedCar = viewModel.selectedCarForExpenses {
                        AddMaintenanceRecordView(
                            selectedCar: selectedCar,
                            prefilledName: record.name,
                            prefilledNotes: record.notes,
                            onAdd: { newRecord in
                                analytics.trackEvent("maintenance_record_duplicated", properties: [
                                    "screen": "planned_maintenance_screen"
                                ])

                                viewModel.addNewMaintenanceRecord(newRecord: newRecord)

                                loadData()
                                onPlannedMaintenaceRecordsUpdated()
                            }
                        )
                    }
                }
            }

            floatingAddButton
        }
    }

    private var floatingAddButton: some SwiftUICore.View {
        Button(action: {
            showingAddMaintenanceRecord = true
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
        .disabled(viewModel.selectedCarForExpenses == nil)
        .opacity(viewModel.selectedCarForExpenses == nil ? 0.5 : 1.0)
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private var filterSection: some SwiftUICore.View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PlannedMaintenanceFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.setFilter(filter)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var paginationControlsView: some SwiftUICore.View {
        VStack(spacing: 12) {
            // Navigation buttons
            HStack(spacing: 16) {
                // Previous button
                Button(action: {
                    viewModel.goToPreviousPage()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(L("Previous"))
                    }
                    .font(.subheadline)
                    .foregroundColor(viewModel.currentPage > 1 ? .blue : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.currentPage <= 1)

                // Current page indicator
                Text("\(viewModel.currentPage)")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(minWidth: 40)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )

                // Next button
                Button(action: {
                    viewModel.goToNextPage()
                }) {
                    HStack(spacing: 4) {
                        Text(L("Next"))
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(viewModel.currentPage < viewModel.totalPages ? .blue : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.currentPage >= viewModel.totalPages)
            }

            // Information text
            Text(String(format: L("Total records: %d, total pages: %d"), viewModel.totalRecords, viewModel.totalPages))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var noFilterResultsView: some SwiftUICore.View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text(L("No records match the selected filter"))
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var mainContent: some SwiftUICore.View {
        if viewModel.totalAllRecords == 0, viewModel.selectedCarForExpenses != nil {
            ScrollView {
                EmptyStateView(selectedCar: viewModel.selectedCarForExpenses)
                    .padding(.vertical)
            }
        } else if viewModel.selectedCarForExpenses != nil {
            List {
                // Filter chips row
                filterSection
                    .padding(.bottom, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                if viewModel.maintenanceRecords.isEmpty {
                    noFilterResultsView
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    // Hint text row
                    Text(L("Swipe right to mark as done, left to edit or delete"))
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    // Maintenance records
                    ForEach(viewModel.maintenanceRecords) { record in
                        Button {
                            analytics.trackEvent(
                                "maintenance_item_clicked",
                                properties: [
                                    "screen": "planned_maintenance_screen",
                                    "action": "view_details"
                                ])
                            recordToShowDetails = record
                        } label: {
                            PlannedMaintenanceItemView(record: record)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                analytics.trackEvent(
                                    "delete_maintenance_button_clicked",
                                    properties: [
                                        "button_name": "delete",
                                        "screen": "planned_maintenance_screen",
                                        "action": "delete_maintenance_record"
                                    ])

                                recordToDelete = record
                                showingDeleteConfirmation = true
                            } label: {
                                Label(L("Delete"), systemImage: "trash")
                            }

                            Button {
                                analytics.trackEvent(
                                    "edit_maintenance_button_clicked",
                                    properties: [
                                        "button_name": "edit",
                                        "screen": "planned_maintenance_screen",
                                        "action": "edit_maintenance_record"
                                    ])

                                recordToEdit = record
                            } label: {
                                Label(L("Edit"), systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                analytics.trackEvent(
                                    "mark_as_done_button_clicked",
                                    properties: [
                                        "button_name": "mark_as_done",
                                        "screen": "planned_maintenance_screen",
                                        "action": "mark_maintenance_as_done"
                                    ])

                                recordToMarkAsDone = record
                            } label: {
                                Label(L("Done"), systemImage: "checkmark.circle.fill")
                            }
                            .tint(.green)
                        }
                    }

                    // Pagination controls
                    if viewModel.totalPages > 1 {
                        paginationControlsView
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }

                    /// Extra padding at the bottom for FAB clearance
                    Spacer()
                        .frame(height: 80)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        } else {
            ScrollView {
                EmptyStateView(selectedCar: viewModel.selectedCarForExpenses)
                    .padding(.vertical)
            }
        }
    }

    private func loadData() {
        viewModel.loadData()
    }

    private func deleteConfirmationAlert() -> Alert {
        let title = Text(L("Delete maintenance record?"))
        let message = Text(L("Delete selected maintenance record? This action cannot be undone."))

        return Alert(
            title: title,
            message: message,
            primaryButton: .destructive(Text(L("Delete"))) {
                if let e = recordToDelete {

                    viewModel.deleteMaintenanceRecord(e)

                    loadData()
                    onPlannedMaintenaceRecordsUpdated()
                }
                recordToDelete = nil
            },
            secondaryButton: .cancel {
                recordToDelete = nil
            }
        )
    }
}

struct EmptyStateView: SwiftUICore.View {
    
    let selectedCar: Car?

    var body: some SwiftUICore.View {
        VStack(alignment: .center, spacing: 16) {
           Image(systemName: "hammer.fill")
               .font(.system(size: 64))
               .foregroundColor(.gray.opacity(0.5))

           Text(L("No maintenance records yet"))
               .font(.title3)
               .foregroundColor(.gray)

           Text(L("Add your first maintenance record"))
               .font(.subheadline)
               .foregroundColor(.gray.opacity(0.9))

            if (selectedCar == nil) {
                Text(L("Please add car first to track maintenance records"))
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.9))
            }
       }
       .padding(.top, 60)
       .padding(.horizontal, 20)
       .multilineTextAlignment(.center)
    }
}
