//
//  AddExpenseView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 10.10.2025.
//
import SwiftUI

struct AddExpenseView: SwiftUICore.View {

    let defaultExpenseType: ExpenseType?
    let defaultCurrency: Currency
    let selectedCar: Car?
    let onAdd: (AddExpenseViewResult) -> Void

    @Environment(\.dismiss) var dismiss
    
    @State private var date = Date()
    @State private var energyCharged = ""
    @State private var chargerType: ChargerType = .home7kW
    @State private var expenseType: ExpenseType? = nil
    @State private var odometer = ""
    @State private var cost = ""
    @State private var notes = ""
    @State private var showingAlert = false
    
    @State private var carName = ""
    @State private var batteryCapacity = ""

    @State private var alertMessage: String? = nil
    
    var body: some SwiftUICore.View {
        NavigationView {
                      
            Form {
                Section(header: Text(NSLocalizedString("Expense details", comment: "Section header for expense details"))) {
                    
                    if (selectedCar != nil) {
                        HStack {
                            Text(NSLocalizedString("Car", comment: "Label for car"))
                            Spacer()
                            Text(selectedCar!.name)
                                .disabled(true)
                        }
                    }

                    DatePicker(NSLocalizedString("Date", comment: "Date picker label"), selection: $date, displayedComponents: .date)

                    if (defaultExpenseType == .charging) {
                        HStack {
                            Text(NSLocalizedString("Energy (kWh)", comment: "Label for energy charged"))
                            Spacer()
                            TextField(NSLocalizedString("45.2", comment: "Placeholder for energy"), text: $energyCharged)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        Picker(NSLocalizedString("Charger Type", comment: "Picker label for charger type"), selection: $chargerType) {
                            ForEach(ChargerType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    } else {
                        Picker(NSLocalizedString("Expense Type", comment: "Picker label for expense type"), selection: $expenseType) {
                            ForEach(ExpenseType.allCases.filter({ $0 != .charging }), id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                    
                    HStack {
                        Text(NSLocalizedString("Odometer (km)", comment: "Label for odometer"))
                        Spacer()
                        TextField(selectedCar?.currentMileage.formatted() ?? "", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text(String(format: NSLocalizedString("Cost (%@)", comment: "Label for cost with currency"), defaultCurrency.rawValue))
                        Spacer()
                        TextField(NSLocalizedString("12.50", comment: "Placeholder for cost"), text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    if (selectedCar == nil) {
                        HStack {
                            Text(NSLocalizedString("Car name", comment: "Label for car name when creating new car"))
                            Spacer()
                            TextField(NSLocalizedString("Name of the car", comment: "Placeholder for car name"), text: $carName)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Spacer()

                            Text(NSLocalizedString("Battery capacity (kWh)", comment: "Label for battery capacity for new car"))
                            Spacer()
                            TextField(NSLocalizedString("75", comment: "Placeholder for battery capacity"), text: $batteryCapacity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                }

                Section(header: Text(NSLocalizedString("Optional", comment: "Section header for optional fields"))) {
                    TextField(NSLocalizedString("Notes (optional)", comment: "Placeholder for optional notes"), text: $notes)
                }
            }
            .navigationTitle(NSLocalizedString("Add expense", comment: "Title for add expense screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Save", comment: "Save button")) {
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
        batteryCapacity = batteryCapacity.replacing(",", with: ".")

        // Unwrap expense type
        let finalExpenseType: ExpenseType?
        if let defaultType = defaultExpenseType {
            finalExpenseType = defaultType
        } else {
            finalExpenseType = expenseType
        }

        guard let expenseTypeUnwrapped = finalExpenseType else {
            alertMessage = NSLocalizedString("Please select an expense type.", comment: "Validation message when expense type not selected")
            return
        }

        var energy = 0.0
        if (expenseTypeUnwrapped == .charging) {
            guard let energyParsed = Double(energyCharged) else {
                alertMessage = NSLocalizedString("Please type a valid value for Energy.", comment: "Validation message for energy")
                return
            }

            energy = energyParsed
        }

        guard let odo = Int(odometer) else {
            alertMessage = NSLocalizedString("Please type a valid value for Odometer.", comment: "Validation message for odometer")
            return
        }
        
        let sessionCost = Double(cost)

        let expense = Expense(
            date: date,
            energyCharged: energy,
            chargerType: chargerType,
            odometer: odo,
            cost: sessionCost,
            notes: notes,
            isInitialRecord: false,
            expenseType: expenseTypeUnwrapped,
            currency: defaultCurrency,
            carId: nil
        )

        var initialExpenseForNewCar: Expense? = nil

        if (selectedCar == nil) {
            initialExpenseForNewCar = Expense(
                date: date,
                energyCharged: 0.0,
                chargerType: .other,
                odometer: odo,
                cost: 0.0,
                notes: "Initial record for tracking car",
                isInitialRecord: true,
                expenseType: .other,
                currency: defaultCurrency,
                carId: nil
            )
        }

        var carNameValue = selectedCar?.name
        if (carNameValue == nil) {
            carNameValue = carName.isEmpty ? nil : carName
        }

        let batteryCapacityValue = Double(batteryCapacity)

        onAdd(
            AddExpenseViewResult(
                expense: expense,
                carName: carNameValue,
                initialOdometr: odo,
                batteryCapacity: batteryCapacityValue,
                initialExpenseForNewCar: initialExpenseForNewCar))
        dismiss()
    }
}

struct AddExpenseViewResult {
    let expense: Expense
    let carName: String?
    let initialOdometr: Int
    let batteryCapacity: Double?
    let initialExpenseForNewCar: Expense?
}

#Preview {
    AddExpenseView(
        defaultExpenseType: nil,
        defaultCurrency: .usd,
        selectedCar: nil,
        onAdd: { session in
            print("Added session: \(session)")
        })
}
