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
    let allCars: [Car]
    let existingExpense: Expense? // For edit mode
    let onAdd: (AddExpenseViewResult) -> Void

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var date = Date()
    @State private var energyCharged = ""
    @State private var chargerType: ChargerType = .home7kW
    @State private var expenseType: ExpenseType? = nil
    @State private var odometer = ""
    @State private var pricePerKWh = ""
    @State private var cost = ""
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var carName = ""
    @State private var batteryCapacity = ""
    @State private var carId: Int64? = nil

    @State private var alertMessage: String? = nil
    @State private var selectedCardForExpense: Car? = nil

    @FocusState private var isPricePerKWhFocused: Bool
    @FocusState private var isCostFocused: Bool
    
    private var isEditMode: Bool {
        existingExpense != nil
    }

    init(
        defaultExpenseType: ExpenseType?,
        defaultCurrency: Currency,
        selectedCar: Car?,
        allCars: [Car],
        existingExpense: Expense? = nil,
        onAdd: @escaping (AddExpenseViewResult) -> Void) {
        self.defaultExpenseType = defaultExpenseType
        self.defaultCurrency = defaultCurrency
        self.selectedCar = selectedCar
        self.allCars = allCars
        self.existingExpense = existingExpense
        self.onAdd = onAdd

        _carId = State(initialValue: self.selectedCar?.id ?? existingExpense?.carId)
        _selectedCardForExpense = State(initialValue: self.selectedCar)

        // Initialize fields with existing expense data if in edit mode
        if let expense = existingExpense {
            _date = State(initialValue: expense.date)
            _energyCharged = State(initialValue: expense.energyCharged > 0 ? String(expense.energyCharged) : "")
            _chargerType = State(initialValue: expense.chargerType)
            _expenseType = State(initialValue: expense.expenseType)
            _odometer = State(initialValue: String(expense.odometer))
            _cost = State(initialValue: expense.cost != nil ? String(expense.cost!) : "")
            _notes = State(initialValue: expense.notes)
            
            // Calculate price per kWh if it's a charging expense
            if expense.expenseType == .charging && expense.energyCharged > 0, let costValue = expense.cost {
                let pricePerKWh = costValue / expense.energyCharged
                _pricePerKWh = State(initialValue: String(format: "%.2f", pricePerKWh))
            }
        }
    }

    var body: some SwiftUICore.View {
        NavigationStack {
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

                Section(header: Text(L("Expense details"))) {

                    if (selectedCardForExpense != nil) {

                        Picker(L("Car"), selection: $carId) {
                            ForEach(allCars, id: \.self.id) { optionCar in
                                Text(optionCar.name)
                                    .tag(optionCar.id)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: carId) { _, newCarId in
                            analytics.trackEvent("car_select_button_clicked", properties: [
                                    "screen": "add_expense_screen",
                                    "action": "add_expense_" + (defaultExpenseType?.rawValue ?? "none"),
                                    "button_name": "car_picker"
                                ])

                            selectedCardForExpense = allCars.first { $0.id == newCarId }
                        }
                        .foregroundColor(isEditMode ? .gray : .primary)
                        .disabled(isEditMode)
                    }

                    DatePicker(L("Date"), selection: $date, displayedComponents: .date)

                    if (defaultExpenseType == .charging) {
                        HStack {
                            Text(L("Energy (kWh)"))
                            Spacer()
                            TextField(L("45.2"), text: $energyCharged)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(isEditMode ? .gray : .primary)
                                .disabled(isEditMode)
                        }

                        HStack {
                            Text(String(format: L("Price per kWh"), defaultCurrency.rawValue))
                            Spacer()
                            TextField(L("65.0"), text: $pricePerKWh)
                                .focused($isPricePerKWhFocused)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(isEditMode ? .gray : .primary)
                                .disabled(isEditMode)
                                .onChange(of: pricePerKWh, { oldValue, newValue in

                                    if (!isPricePerKWhFocused) {
                                        return
                                    }

                                    guard let pricePerKWhValue = Double(pricePerKWh.replacing(",", with: ".")) else {
                                        return
                                    }

                                    guard let energyChargedValue = Double(energyCharged.replacing(",", with: ".")) else {
                                        return
                                    }

                                    let totalCost = pricePerKWhValue * energyChargedValue
                                    cost = String(format: "%.2f", totalCost)
                                })
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
                        .foregroundColor(isEditMode ? .gray : .primary)
                        .disabled(isEditMode)
                    }
                    
                    VStack {
                        HStack {
                            Text(L("Odometer (km)"))
                            Spacer()
                            TextField(selectedCardForExpense?.currentMileage.formatted() ?? "", text: $odometer)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(isEditMode ? .gray : .primary)
                                .disabled(isEditMode)
                        }

                        Text(L("If you leave it empty, the current mileage of the selected car will be used."))
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text(String(format: L("Cost (%@)"), defaultCurrency.rawValue))
                        Spacer()
                        TextField(L("12.50"), text: $cost)
                            .focused($isCostFocused)
                            .onChange(of: cost, { oldValue, newValue in
                                
                                if (!isCostFocused) {
                                    return
                                }

                                guard let energyChargedValue = Double(energyCharged.replacing(",", with: ".")) else {
                                    return
                                }

                                guard let costValue = Double(newValue.replacing(",", with: ".")) else {
                                    return
                                }

                                if (energyChargedValue > 0) {
                                    let pricePerKWhValue = costValue / energyChargedValue
                                    pricePerKWh = String(format: "%.2f", pricePerKWhValue)
                                }
                            })
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    

                    if (selectedCardForExpense == nil) {
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

                Section {
                    FormButtonsView(
                        onCancel: {
                            analytics.trackEvent("cancel_button_clicked", properties: [
                                    "button_name": "cancel",
                                    "screen": isEditMode ? "edit_expense_screen" : "add_expense_screen",
                                    "action": (isEditMode ? "edit_expense_" : "add_expense_") + (defaultExpenseType?.rawValue ?? "none")
                                ])

                            dismiss()
                        },
                        onSave: {
                            analytics.trackEvent("save_button_clicked", properties: [
                                    "button_name": "save",
                                    "screen": isEditMode ? "edit_expense_screen" : "add_expense_screen",
                                    "action": (isEditMode ? "edit_expense_" : "add_expense_") + (defaultExpenseType?.rawValue ?? "none")
                                ])

                            saveSession()
                        }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle(L(isEditMode ? "Edit expense" : "Add expense"))
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cancel")) {
                        analytics.trackEvent("cancel_toolbaar_button_clicked", properties: [
                                "button_name": "cancel",
                                "screen": isEditMode ? "edit_expense_screen" : "add_expense_screen",
                                "action": (isEditMode ? "edit_expense_" : "add_expense_") + (defaultExpenseType?.rawValue ?? "none")
                            ])

                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Save")) {
                        analytics.trackEvent("save_toolbaar_button_clicked", properties: [
                                "button_name": "save",
                                "screen": isEditMode ? "edit_expense_screen" : "add_expense_screen",
                                "action": (isEditMode ? "edit_expense_" : "add_expense_") + (defaultExpenseType?.rawValue ?? "none")
                            ])

                        saveSession()
                    }
                }
            }
            .onAppear() {

                analytics.trackScreen(
                    isEditMode ? "edit_expense_screen" : "add_expense_screen", properties: [
                        "default_expense_type": defaultExpenseType?.rawValue ?? "none"
                    ])
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

        var currentMileageValue: Int? = Int(odometer)
        if currentMileageValue == nil {
            if (selectedCardForExpense == nil) {
                alertMessage = L("Please type a valid value for Odometer.")
                return
            }

            currentMileageValue = selectedCardForExpense!.currentMileage
        }

        let sessionCost = Double(cost)

        let expense = Expense(
            id: existingExpense?.id, // Preserve ID when editing
            date: date,
            energyCharged: energy,
            chargerType: chargerType,
            odometer: currentMileageValue!,
            cost: sessionCost,
            notes: notes,
            isInitialRecord: existingExpense?.isInitialRecord ?? false,
            expenseType: expenseTypeUnwrapped,
            currency: defaultCurrency,
            carId: selectedCardForExpense?.id ?? existingExpense?.carId
        )

        var initialExpenseForNewCar: Expense? = nil

        if (selectedCardForExpense == nil && existingExpense == nil) {
            initialExpenseForNewCar = Expense(
                date: date,
                energyCharged: 0.0,
                chargerType: .other,
                odometer: currentMileageValue!,
                cost: 0.0,
                notes: L("Initial record for tracking car"),
                isInitialRecord: true,
                expenseType: .other,
                currency: defaultCurrency,
                carId: nil
            )
        }

        var carNameValue = selectedCardForExpense?.name
        if (carNameValue == nil) {
            carNameValue = carName.isEmpty ? nil : carName
        }

        let batteryCapacityValue = Double(batteryCapacity)

        onAdd(
            AddExpenseViewResult(
                expense: expense,
                carName: carNameValue,
                carId: carId,
                initialOdometr: currentMileageValue!,
                batteryCapacity: batteryCapacityValue,
                initialExpenseForNewCar: initialExpenseForNewCar))
        dismiss()
    }
}

struct AddExpenseViewResult {
    let expense: Expense
    let carName: String?
    let carId: Int64?
    let initialOdometr: Int
    let batteryCapacity: Double?
    let initialExpenseForNewCar: Expense?
}

#Preview {
    AddExpenseView(
        defaultExpenseType: nil,
        defaultCurrency: .usd,
        selectedCar: nil,
        allCars: [],
        onAdd: { session in
            GlobalLogger.shared.info("Added session: \(session)")
        })
}
