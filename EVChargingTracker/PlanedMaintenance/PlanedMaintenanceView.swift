//
//  PlanedMaintenanceView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

import Foundation
import SwiftUI

struct PlanedMaintenanceView: SwiftUICore.View {

    @StateObject private var viewModel = PlanedMaintenanceViewModel()
    @State private var showingAddMaintenanceRecord = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var recordToDelete: PlannedMaintenanceItem? = nil

    init() {
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
    }

    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Button(action: {
                            showingAddMaintenanceRecord = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text(L("Add maintenance"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .disabled(viewModel.selectedCarForExpenses == nil)

                        if viewModel.maintenanceRecords.isEmpty {
                            EmptyStateView(selectedCar: viewModel.selectedCarForExpenses)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.maintenanceRecords) { record in
                                    PlannedMaintenanceItemView(
                                        record: record,
                                        onDelete: {
                                            recordToDelete = record
                                            showingDeleteConfirmation = true
                                        })
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            } // end of ZStack
            .navigationTitle(L("Planned maintenance"))
            .navigationBarTitleDisplayMode(.automatic)
            .onAppear {
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
                        _ = viewModel.repository.insertRecord(newRecord)
                        loadData()
                    }
                )
                    
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
                    _ = viewModel.repository.deleteRecord(id: e.id)
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
       .padding(.horizontal)
    }
}
