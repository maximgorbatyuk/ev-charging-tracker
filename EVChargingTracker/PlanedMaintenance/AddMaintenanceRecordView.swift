//
//  AddMaintenanceRecordView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 05.11.2025.
//

import SwiftUI

struct AddMaintenanceRecordView: SwiftUICore.View {
    let selectedCar: Car?
    let onAdd: (PlannedMaintenance) -> Void
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var when = Date()
    @State private var odometer = ""
    @State private var name = ""
    @State private var notes = ""

    @State private var remindByDate = false
    @State private var remindByOdometer = false
    @State private var alertMessage: String? = nil
    
    var body: some SwiftUICore.View {
        NavigationView {
            Form {

                if (alertMessage != nil) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 28))

                        Text(alertMessage!)
                            .fontWeight(.semibold)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(8)
                    .listRowBackground(Color.yellow.opacity(0.2))
                    .background(Color.clear)
                }

                Section(header: Text(L("Maintenance details"))) {

                    if (selectedCar != nil) {
                        HStack {
                            Text(L("Car"))
                            Spacer()
                            Text(selectedCar!.name)
                                .disabled(true)
                        }
                    }

                    TextField(L("What should be done?"), text: $name)

                    VStack {
                        Toggle(L("Remind by date (optional)"), isOn: $remindByDate)
                        DatePicker(L("When"), selection: $when, displayedComponents: .date)
                            .disabled(!remindByDate)
                            .foregroundColor(remindByDate ? .primary : .gray)
                    }

                    VStack {
                        Toggle(L("Remind by odometer (optional)"), isOn: $remindByOdometer)
                        TextField(selectedCar!.currentMileage.formatted(), text: $odometer)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .disabled(!remindByOdometer)
                            .foregroundColor(remindByOdometer ? .primary : .gray)
                    }
                }

                Section(header: Text(L("Notes (optional)"))) {
                    TextField(L("Additional information that will be helpful"), text: $notes)
                }
            } // Form end
            .navigationTitle(L("Plan a maintenance"))
            .navigationBarTitleDisplayMode(.automatic)
            .safeAreaInset(edge: .bottom) {
                FormButtonsView(
                    onCancel: {
                        analytics.trackEvent("cancel_maintenance_button_clicked", properties: [
                                "button_name": "cancel",
                                "screen": "add_planned_maintenance_record"
                            ])

                        dismiss()
                    },
                    onSave: {
                        analytics.trackEvent("save_maintenance_button_clicked", properties: [
                                "button_name": "save",
                                "screen": "add_planned_maintenance_record"
                            ])

                        save()
                    }
                )
                .padding(.bottom, 30)
                .padding(.horizontal, 20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cancel")) {
                        analytics.trackEvent("cancel_maintenance_button_clicked", properties: [
                                "button_name": "cancel",
                                "screen": "add_planned_maintenance_record"
                            ])

                        dismiss()
                    }
                }
            }
        } // NavigationView end
    }
    
    private func save() {
        
        alertMessage = nil
        if (selectedCar == nil) {
            alertMessage = L("Please select a car first.")
            return
        }
        
        if (name == "") {
            alertMessage = L("Please type service title.")
            return
        }

        var odo: Int? = nil
        if (remindByOdometer && odometer != nil && odometer != "") {
            guard let odometerValue = Int(odometer) else {
                // TODO mgorbatyuk: show alert
                alertMessage = L("Please type a valid value for Odometer.")
                return
            }

            odo = odometerValue
        }

        let record = PlannedMaintenance(
            when: remindByDate ? when : nil,
            odometer: remindByOdometer ? odo : nil,
            name: name,
            notes: notes,
            carId: selectedCar!.id!
        )

        onAdd(record)
        dismiss()
    }
}
