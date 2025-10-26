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
    @ObservedObject private var loc = LocalizationManager.shared
    
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
                Section(header: Text(L("Expense details"))) {
                    
                    if (selectedCar != nil) {
                        HStack {
                            Text(L("Car"))
                            Spacer()
                            Text(selectedCar!.name)
                                .disabled(true)
                        }
                    }

                    DatePicker(L("Date"), selection: $date, displayedComponents: .date)

                    if (defaultExpenseType == .charging) {
                        HStack {
                            Text(L("Energy (kWh)"))
                            Spacer()
                            TextField(L("45.2"), text: $energyCharged)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        Picker(L("Charger Type"), selection: $chargerType) {
                            ForEach(ChargerType.allCases, id: \.self) { type in
                                Text(L(type.rawValue)).tag(type)
                            }
                        }
                    } else {
                        Picker(L("Expense Type"), selection: $expenseType) {
                            ForEach(ExpenseType.allCases.filter({ $0 != .charging }), id: \.self) { type in
                                Text(L(type.rawValue)).tag(type)
                            }
                        }
                    }
                    
                    HStack {
                        Text(L("Odometer (km)"))
                        Spacer()
                        TextField(selectedCar?.currentMileage.formatted() ?? "", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text(String(format: L("Cost (%@)"), defaultCurrency.rawValue))
                        Spacer()
                        TextField(L("12.50"), text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    if (selectedCar == nil) {
                        HStack {
                            Text(L("Car name"))
                            Spacer()
                            TextField(L("Name of the car"), text: $carName)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Spacer()

                            Text(L("Battery capacity (kWh)"))
                            Spacer()
                            TextField(L("75"), text: $batteryCapacity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                }

                Section(header: Text(L("Optional"))) {
                    TextField(L("Notes (optional)"), text: $notes)
                }
            }
            .navigationTitle(L("Add expense"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Save")) {
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
            alertMessage = L("Please select an expense type.")
            return
        }

        var energy = 0.0
        if (expenseTypeUnwrapped == .charging) {
            guard let energyParsed = Double(energyCharged) else {
                alertMessage = L("Please type a valid value for Energy.")
                return
            }

            energy = energyParsed
        }

        guard let odo = Int(odometer) else {
            alertMessage = L("Please type a valid value for Odometer.")
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
                notes: L("Initial record for tracking car"),
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
