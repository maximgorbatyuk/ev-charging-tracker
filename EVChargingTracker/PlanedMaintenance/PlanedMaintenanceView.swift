//
//  PlanedMaintenanceView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

import SwiftUI

struct PlanedMaintenanceView: SwiftUICore.View {

    @StateObject private var viewModel = PlanedMaintenanceViewModel()
    @State private var showingAddMaintenanceRecord = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var recordToDelete: PlannedMaintenanceItem? = nil
    
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

                        if viewModel.maintenanceRecords.isEmpty {
                            emptyStateView
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
            .navigationTitle(L("Maintenance"))
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
                
            }
        }
    }

    private func loadData() {
        viewModel.loadData()
    }

    private var emptyStateView: some SwiftUICore.View {
       VStack(spacing: 16) {
           Image(systemName: "hammer.fill")
               .font(.system(size: 64))
               .foregroundColor(.gray.opacity(0.5))

           Text(L("No maintenance records yet"))
               .font(.title3)
               .foregroundColor(.gray)

           Text(L("Add your first maintenance record"))
               .font(.subheadline)
               .foregroundColor(.gray.opacity(0.9))
       }
       .padding(.top, 60)
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

struct PlannedMaintenanceItemView: SwiftUICore.View {
    
    @Environment(\.colorScheme) var colorScheme

    let record: PlannedMaintenanceItem
    let onDelete: () -> Void

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(record.name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.9))

                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("When"))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(record.when, style: .date)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Odometer"))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("\(record.odometer.formatted()) km")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.9))
                }
            }

            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
