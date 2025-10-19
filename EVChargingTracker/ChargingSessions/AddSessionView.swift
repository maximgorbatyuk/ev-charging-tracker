//
//  AddSessionView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 10.10.2025.
//
import SwiftUI

struct AddSessionView: SwiftUICore.View {

    let defaultExpenseType: ExpenseType?
    let defaultCurrency: Currency
    let showFirstTrackingRecordToggle: Bool
    let onAdd: (Expense) -> Void

    @Environment(\.dismiss) var dismiss
    
    @State private var date = Date()
    @State private var energyCharged = ""
    @State private var chargerType: ChargerType = .home7kW
    @State private var expenseType: ExpenseType? = nil
    @State private var odometer = ""
    @State private var cost = ""
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var isInitialRecord = false

    @State private var alertMessage: String? = nil
    
    var body: some SwiftUICore.View {
        NavigationView {
            Form {
                Section(header: Text("Session Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    if (defaultExpenseType == .charging) {
                        HStack {
                            Text("Energy (kWh)")
                            Spacer()
                            TextField("45.2", text: $energyCharged)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        Picker("Charger Type", selection: $chargerType) {
                            ForEach(ChargerType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    } else {
                        // TODO mgorbatyuk: implement other expense types
                        
                        Picker("Expense Type", selection: $expenseType) {
                            ForEach(ExpenseType.allCases.filter({ $0 != .charging }), id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }

                    
                    HStack {
                        Text("Odometer (km)")
                        Spacer()
                        TextField("12345", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    if (showFirstTrackingRecordToggle) {
                        HStack {
                            Spacer()
                            Toggle("First record to start tracking?", isOn: $isInitialRecord)
                        }
                    }
                    
                }
                
                Section(header: Text("Optional")) {
                    HStack {
                        Text("Cost (\(defaultCurrency.rawValue))")
                        Spacer()
                        TextField("12.50", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Add Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSession()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveSession() {

        cost = cost.replacing(",", with: ".")
        energyCharged = energyCharged.replacing(",", with: ".")

        // Unwrap expense type
        let finalExpenseType: ExpenseType?
        if let defaultType = defaultExpenseType {
            finalExpenseType = defaultType
        } else {
            finalExpenseType = expenseType
        }

        guard let expenseTypeUnwrapped = finalExpenseType else {
            alertMessage = "Please select an expense type."
            return
        }

        var energy = 0.0
        if (expenseTypeUnwrapped == .charging) {
            guard let energyParsed = Double(energyCharged) else {
                alertMessage = "Please type a valid value for Energy."
                return
            }

            energy = energyParsed
        }

        guard let odo = Int(odometer) else {
            alertMessage = "Please type a valid value for Odometer."
            return
        }
        
        let sessionCost = Double(cost)

        let session = Expense(
            date: date,
            energyCharged: energy,
            chargerType: chargerType,
            odometer: odo,
            cost: sessionCost,
            notes: notes,
            isInitialRecord: isInitialRecord,
            expenseType: expenseTypeUnwrapped,
            currency: defaultCurrency
        )

        onAdd(session)
        dismiss()
    }
}

#Preview {
    AddSessionView(
        defaultExpenseType: nil,
        defaultCurrency: .usd,
        showFirstTrackingRecordToggle: false,
        onAdd: { session in
            print("Added session: \(session)")
        })
}
