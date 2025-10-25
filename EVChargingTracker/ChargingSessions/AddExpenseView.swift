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
                Section(header: Text("Expense details")) {
                    
                    if (selectedCar != nil) {
                        HStack {
                            Text("Car")
                            Spacer()
                            Text(selectedCar!.name)
                                .disabled(true)
                        }
                    }

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
                        Picker("Expense Type", selection: $expenseType) {
                            ForEach(ExpenseType.allCases.filter({ $0 != .charging }), id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Odometer (km)")
                        Spacer()
                        TextField(selectedCar?.currentMileage.formatted() ?? "", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Cost (\(defaultCurrency.rawValue))")
                        Spacer()
                        TextField("12.50", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    if (selectedCar == nil) {
                        HStack {
                            Text("Car name")
                            Spacer()
                            TextField("Name of the car", text: $carName)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Spacer()

                            Text("Battery capacity (kWh)")
                            Spacer()
                            TextField("75", text: $batteryCapacity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                }

                Section(header: Text("Optional")) {
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Add expense")
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
        batteryCapacity = batteryCapacity.replacing(",", with: ".")

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
