//
//  AddExpenseView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 10.10.2025.
//
import SwiftUI

/// Charge vs Fuel entry for the charging-flow form. Only Hybrid cars expose the
/// switcher; Electric cars stay charge-only.
enum ExpenseEntryMode: String {
    case charge
    case fuel
}

struct AddExpenseView: SwiftUICore.View {

    static let ExpenseFormatWithTwoDigits = "%.2f"
    static let ExpenseFormatWithThreeDigits = "%.3f"

    let defaultExpenseType: ExpenseType?
    let defaultCurrency: Currency
    let selectedCar: Car?
    let allCars: [Car]
    let existingExpense: Expense?
    let onAdd: (AddExpenseViewResult) -> Void
    let lastChargingSession: Expense?
    let lastFuelSession: Expense?
    let prefilledTitle: String?
    let prefilledNotes: String?

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var date = Date()
    @State private var energyCharged = ""
    @State private var chargerType: ChargerType = .home7kW
    @State private var expenseType: ExpenseType?
    @State private var odometer = ""
    @State private var pricePerKWh = ""
    @State private var cost = ""
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var carName = ""
    @State private var batteryCapacity = ""
    @State private var carId: Int64?

    @State private var alertMessage: String?
    @State private var selectedCardForExpense: Car?

    // Store price and charger type from the stored expense
    @State private var storedPricePerKWh: String = ""
    @State private var storedChargerType: ChargerType?

    // Charge/Fuel mode and fuel-specific inputs (Hybrid cars only).
    @State private var mode: ExpenseEntryMode = .charge
    @State private var fuelType: FuelType = .octane95
    @State private var fuelVolumeText = ""
    @State private var fuelPricePerUnitText = ""

    @FocusState private var isCountOfKWtFocused: Bool
    @FocusState private var isPricePerKWhFocused: Bool
    @FocusState private var isCostFocused: Bool
    @FocusState private var isFuelVolumeFocused: Bool
    @FocusState private var isFuelPriceFocused: Bool

    private var isEditMode: Bool {
        existingExpense != nil
    }

    init(
        defaultExpenseType: ExpenseType?,
        defaultCurrency: Currency,
        selectedCar: Car?,
        allCars: [Car],
        existingExpense: Expense? = nil,
        lastChargingSession: Expense? = nil,
        lastFuelSession: Expense? = nil,
        prefilledTitle: String? = nil,
        prefilledNotes: String? = nil,
        onAdd: @escaping (AddExpenseViewResult) -> Void
    ) {
        self.defaultExpenseType = defaultExpenseType
        self.defaultCurrency = defaultCurrency
        self.selectedCar = selectedCar
        self.allCars = allCars
        self.existingExpense = existingExpense
        self.onAdd = onAdd
        self.lastChargingSession = lastChargingSession
        self.lastFuelSession = lastFuelSession
        self.prefilledTitle = prefilledTitle
        self.prefilledNotes = prefilledNotes

        _carId = State(initialValue: self.selectedCar?.id ?? existingExpense?.carId)
        _selectedCardForExpense = State(initialValue: self.selectedCar)

        /// Pre-select expense type for non-charging expenses
        if let expType = defaultExpenseType, expType != .charging {
            _expenseType = State(initialValue: expType)
        }

        /// Pre-fill notes from maintenance record if provided
        if let title = prefilledTitle, let extraNotes = prefilledNotes {
            if extraNotes.isEmpty {
                _notes = State(initialValue: title)
            } else {
                _notes = State(initialValue: "\(title)\n\(extraNotes)")
            }
        } else if let title = prefilledTitle {
            _notes = State(initialValue: title)
        } else if let extraNotes = prefilledNotes {
            _notes = State(initialValue: extraNotes)
        }

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
                let pricePerKWhString = String(format: AddExpenseView.ExpenseFormatWithThreeDigits, pricePerKWh)
                _pricePerKWh = State(initialValue: pricePerKWhString)

                // Store the price and charger type from the expense
                _storedPricePerKWh = State(initialValue: pricePerKWhString)
                _storedChargerType = State(initialValue: expense.chargerType)
            }
        } else if let lastChargingSession = lastChargingSession {
            _chargerType = State(initialValue: lastChargingSession.chargerType)
            _expenseType = State(initialValue: .charging)

            if let lastChargingPricePerKWh = lastChargingSession.getPricePerKWh() {
                let pricePerKWhString = String(
                    format: AddExpenseView.ExpenseFormatWithThreeDigits,
                    lastChargingPricePerKWh)
                _pricePerKWh = State(initialValue: pricePerKWhString)

                // Store the price and charger type from the last session
                _storedPricePerKWh = State(initialValue: pricePerKWhString)
                _storedChargerType = State(initialValue: lastChargingSession.chargerType)
            }
        }

        // Fuel mode + fuel-field prefill. Octane and price-per-unit carry over
        // from the edited expense (edit) or the last fuel session (new); volume
        // always starts empty.
        _mode = State(initialValue: existingExpense?.expenseType == .fuel ? .fuel : .charge)

        if let expense = existingExpense, expense.expenseType == .fuel {
            if let savedFuelType = expense.fuelType {
                _fuelType = State(initialValue: savedFuelType)
            }

            // Edit mode restores the stored volume; a blank field would hide the
            // saved value and block Save (isFuelFormValid needs volume > 0).
            if let volume = expense.fuelVolume {
                _fuelVolumeText = State(
                    initialValue: String(format: AddExpenseView.ExpenseFormatWithTwoDigits, volume))
            }

            if let price = expense.getFuelPricePerUnit() {
                _fuelPricePerUnitText = State(
                    initialValue: String(format: AddExpenseView.ExpenseFormatWithThreeDigits, price))
            }
        } else if let lastFuelSession = lastFuelSession {
            if let savedFuelType = lastFuelSession.fuelType {
                _fuelType = State(initialValue: savedFuelType)
            }

            if let price = lastFuelSession.getFuelPricePerUnit() {
                _fuelPricePerUnitText = State(
                    initialValue: String(format: AddExpenseView.ExpenseFormatWithThreeDigits, price))
            }
        }
    }

    private var showsChargeOrFuelFields: Bool {
        defaultExpenseType == .charging || defaultExpenseType == .fuel
    }

    private var showsModeSwitcher: Bool {
        existingExpense == nil &&
        defaultExpenseType == .charging &&
        selectedCardForExpense?.carType == .hybrid
    }

    private var isFuelFormValid: Bool {
        guard let volume = Double(fuelVolumeText.replacing(",", with: ".")),
              volume > 0
        else {
            return false
        }

        guard let price = Double(fuelPricePerUnitText.replacing(",", with: ".")),
              price >= 0
        else {
            return false
        }

        return true
    }

    /// Charging needs a positive energy value; cost stays optional so free
    /// charging can still be logged (mirrors the guard in `saveSession()`).
    private var isChargeFormValid: Bool {
        guard let energy = Double(energyCharged.replacing(",", with: ".")),
              energy > 0
        else {
            return false
        }

        return true
    }

    private var isSaveDisabled: Bool {
        switch mode {
        case .fuel:
            return !isFuelFormValid
        case .charge:
            return showsChargeOrFuelFields && !isChargeFormValid
        }
    }

    var body: some SwiftUICore.View {
        NavigationStack {
            Form {
                if alertMessage != nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 28))

                        Text(alertMessage!)
                            .fontWeight(.semibold)
                            .appFont(.custom(size: 16), weight: .bold)
                    }
                    .padding(8)
                    .listRowBackground(Color.yellow.opacity(0.2))
                    .background(Color.clear)
                }

                Section(header: Text(L("Expense details"))) {

                    if selectedCardForExpense != nil && allCars.count > 1 {

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

                            // Electric cars are charge-only — drop any fuel input.
                            if selectedCardForExpense?.carType == .electric {
                                mode = .charge
                                fuelVolumeText = ""
                                fuelPricePerUnitText = ""
                            }
                        }
                        .foregroundColor(isEditMode ? .gray : .primary)
                        .disabled(isEditMode)
                    }

                    if showsModeSwitcher {
                        modeSwitcher
                    }

                    DatePicker(L("Date"), selection: $date, displayedComponents: .date)

                    if showsChargeOrFuelFields {
                        if mode == .charge {
                            chargeFields
                        } else {
                            fuelFields
                        }
                    } else {
                        Picker(L("Expense Type"), selection: $expenseType) {
                            ForEach(ExpenseType.allCases.filter({ $0 != .charging && $0 != .fuel }), id: \.self) { type in
                                Text(L(type.rawValue)).tag(type)
                            }
                        }
                        .foregroundColor(isEditMode ? .gray : .primary)
                        .disabled(isEditMode)
                    }

                    VStack {
                        HStack {
                            let unit = selectedCardForExpense?.measurementSystem.distanceUnitLabel ?? L("km")
                            Text(String(format: L("Odometer (%@)"), unit))
                            Spacer()
                            TextField(selectedCardForExpense?.currentMileage.formatted() ?? "", text: $odometer)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }

                        Text(L("If you leave it empty, the current mileage of the selected car will be used."))
                            .appFont(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        Text(String(format: L("Cost (%@)"), defaultCurrency.rawValue))
                        Spacer()
                        TextField(L("12.50"), text: $cost)
                            .focused($isCostFocused)
                            .onChange(of: cost, { _, _ in

                                if !isCostFocused {
                                    return
                                }

                                if mode == .fuel {
                                    adjustFuelPriceBasedOnCost()
                                } else if defaultExpenseType == .charging {
                                    adjustEnergyBasedOnCost()
                                } else {
                                    adjustPriceBasedOnInputs()
                                }
                            })
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    if selectedCardForExpense == nil {
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
                                    "action": (isEditMode ? "edit_expense_" : "add_expense_") + (defaultExpenseType?.rawValue ?? "none"),
                                    "expense_mode": mode.rawValue
                                ])

                            saveSession()
                        },
                        isSaveDisabled: isSaveDisabled
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
                                "action": (isEditMode ? "edit_expense_" : "add_expense_") + (defaultExpenseType?.rawValue ?? "none"),
                                "expense_mode": mode.rawValue
                            ])

                        saveSession()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .onAppear {

                analytics.trackScreen(
                    isEditMode ? "edit_expense_screen" : "add_expense_screen", properties: [
                        "default_expense_type": defaultExpenseType?.rawValue ?? "none"
                    ])
            }
        }
    }

    @ViewBuilder
    private var chargeFields: some SwiftUICore.View {
        HStack {
            Text(L("Energy (kWh)"))
            Spacer()
            TextField(L("45.2"), text: $energyCharged)
                .focused($isCountOfKWtFocused)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: energyCharged, { _, _ in
                    if !isCountOfKWtFocused {
                        return
                    }

                    adjustCostsBasedOnInputs()
                })
        }

        HStack {
            Text(String(format: L("Price per kWh"), defaultCurrency.rawValue))
            Spacer()
            TextField(L("65.0"), text: $pricePerKWh)
                .focused($isPricePerKWhFocused)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: pricePerKWh, { _, _ in
                    if !isPricePerKWhFocused {
                        return
                    }

                    adjustCostsBasedOnInputs()
                })
        }

        Picker(L("Charger Type"), selection: $chargerType) {
            ForEach(ChargerType.allCases, id: \.self) { type in
                Text(L(type.rawValue)).tag(type)
            }
        }
        .onChange(of: chargerType) { oldChargerType, newChargerType in
            handleChargerTypeChange(from: oldChargerType, to: newChargerType)
        }
    }

    @ViewBuilder
    private var fuelFields: some SwiftUICore.View {
        Picker(L("Fuel type"), selection: $fuelType) {
            ForEach(FuelType.allCases, id: \.self) { type in
                Text(type.localizedName).tag(type)
            }
        }

        HStack {
            let volumeUnit = selectedCardForExpense?.measurementSystem.volumeUnitLabel ?? L("L")
            Text("\(L("Volume")) (\(volumeUnit))")
            Spacer()
            TextField(L("45.2"), text: $fuelVolumeText)
                .focused($isFuelVolumeFocused)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: fuelVolumeText, { _, _ in
                    if !isFuelVolumeFocused {
                        return
                    }

                    adjustFuelCostBasedOnInputs()
                })
        }

        HStack {
            Text(fuelPriceLabel)
            Spacer()
            TextField(L("65.0"), text: $fuelPricePerUnitText)
                .focused($isFuelPriceFocused)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: fuelPricePerUnitText, { _, _ in
                    if !isFuelPriceFocused {
                        return
                    }

                    adjustFuelCostBasedOnInputs()
                })
        }
    }

    private var fuelPriceLabel: String {
        selectedCardForExpense?.measurementSystem == .imperial
            ? L("Price per gallon")
            : L("Price per litre")
    }

    /// Charge/Fuel toggle: both options carry their brand tint at all times
    /// (green for charge, purple for fuel); the active one gets a solid fill.
    @ViewBuilder
    private var modeSwitcher: some SwiftUICore.View {
        HStack(spacing: 8) {
            modeSwitcherButton(
                title: L("Charge"),
                isSelected: mode == .charge,
                activeColor: AppColors.green,
                softColor: AppColors.greenSoft,
                action: { mode = .charge })

            modeSwitcherButton(
                title: L("Fuel"),
                isSelected: mode == .fuel,
                activeColor: AppColors.purple,
                softColor: AppColors.purpleSoft,
                action: { mode = .fuel })
        }
        .onChange(of: mode) { _, newMode in
            analytics.trackEvent("expense_mode_switched", properties: [
                    "screen": "add_expense_screen",
                    "mode": newMode.rawValue
                ])
        }
    }

    private func modeSwitcherButton(
        title: String,
        isSelected: Bool,
        activeColor: Color,
        softColor: Color,
        action: @escaping () -> Void
    ) -> some SwiftUICore.View {
        Button(action: action) {
            Text(title)
                .appFont(.subheadline, weight: isSelected ? .semibold : .medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundColor(isSelected ? .white : activeColor)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? activeColor : softColor))
        }
        .buttonStyle(.plain)
    }

    /// Fuel: cost = volume × price. Called when the volume field changes.
    private func adjustFuelCostBasedOnInputs() {
        guard let volume = Double(fuelVolumeText.replacing(",", with: ".")),
              let price = Double(fuelPricePerUnitText.replacing(",", with: "."))
        else {
            return
        }

        cost = String(format: "%.2f", FuelCalc.cost(volume: volume, price: price))
    }

    /// Fuel: price/unit = cost / volume. The volume the user typed is the anchor,
    /// so editing cost (or price) recomputes the other field and never volume.
    private func adjustFuelPriceBasedOnCost() {
        guard let costValue = Double(cost.replacing(",", with: ".")),
              let volume = Double(fuelVolumeText.replacing(",", with: ".")),
              let price = FuelCalc.price(cost: costValue, volume: volume)
        else {
            return
        }

        fuelPricePerUnitText = String(format: AddExpenseView.ExpenseFormatWithThreeDigits, price)
    }

    private func adjustCostsBasedOnInputs() {
        guard let pricePerKWhValue = Double(pricePerKWh.replacing(",", with: ".")) else {
            return
        }

        guard let energyChargedValue = Double(energyCharged.replacing(",", with: ".")) else {
            return
        }

        let totalCost = pricePerKWhValue * energyChargedValue
        cost = String(format: "%.2f", totalCost)
    }

    private func adjustPriceBasedOnInputs() {
        guard let energyChargedValue = Double(energyCharged.replacing(",", with: ".")) else {
            return
        }

        guard let costValue = Double(cost.replacing(",", with: ".")) else {
            return
        }

        if energyChargedValue > 0 {
            let pricePerKWhValue = costValue / energyChargedValue
            pricePerKWh = String(format: AddExpenseView.ExpenseFormatWithThreeDigits, pricePerKWhValue)
        }
    }

    /// When Cost changes: Energy = Cost / Price (Price stays static)
    private func adjustEnergyBasedOnCost() {
        guard let costValue = Double(cost.replacing(",", with: ".")),
              let priceValue = Double(pricePerKWh.replacing(",", with: ".")),
              priceValue > 0
        else {
            return
        }

        let energyValue = costValue / priceValue
        energyCharged = String(format: "%.2f", energyValue)
    }

    private func handleChargerTypeChange(from oldType: ChargerType, to newType: ChargerType) {
        // Check if the new charger type matches the stored expense's charger type
        if let storedType = storedChargerType, newType == storedType, !storedPricePerKWh.isEmpty {
            // Restore the price from the stored expense
            pricePerKWh = storedPricePerKWh

            // Recalculate cost based on restored price
            adjustCostsBasedOnInputs()
        } else {
            adjustPriceBasedOnInputs()
        }
    }

    private func saveSession() {

        cost = cost.replacing(",", with: ".")
        energyCharged = energyCharged.replacing(",", with: ".")
        batteryCapacity = batteryCapacity.replacing(",", with: ".")
        fuelVolumeText = fuelVolumeText.replacing(",", with: ".")

        // Unwrap expense type — the charge/fuel flow is driven by `mode`.
        let finalExpenseType: ExpenseType?
        if showsChargeOrFuelFields {
            finalExpenseType = (mode == .fuel) ? .fuel : .charging
        } else if let defaultType = defaultExpenseType {
            finalExpenseType = defaultType
        } else {
            finalExpenseType = expenseType
        }

        guard let expenseTypeUnwrapped = finalExpenseType else {
            alertMessage = L("Please select an expense type.")
            return
        }

        var energy = 0.0
        var fuelTypeToSave: FuelType?
        var fuelVolumeToSave: Double?

        if expenseTypeUnwrapped == .charging {
            guard let energyParsed = Double(energyCharged) else {
                alertMessage = L("Please type a valid value for Energy.")
                return
            }

            energy = energyParsed
        } else if expenseTypeUnwrapped == .fuel {
            guard let volumeParsed = Double(fuelVolumeText),
                  volumeParsed > 0
            else {
                alertMessage = L("Fuel.Error.VolumeInvalid")
                return
            }

            guard let priceParsed = Double(fuelPricePerUnitText.replacing(",", with: ".")),
                  priceParsed >= 0
            else {
                alertMessage = L("Fuel.Error.PriceInvalid")
                return
            }

            fuelTypeToSave = fuelType
            fuelVolumeToSave = volumeParsed

            // Price-per-unit is derived from cost, so a fuel entry must persist a
            // cost; synthesize it from volume × price when the field is empty.
            if Double(cost) == nil {
                cost = String(format: "%.2f", FuelCalc.cost(volume: volumeParsed, price: priceParsed))
            }
        }

        var currentMileageValue: Int? = Int(odometer)
        if currentMileageValue == nil {
            if selectedCardForExpense == nil {
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
            carId: selectedCardForExpense?.id ?? existingExpense?.carId,
            fuelType: fuelTypeToSave,
            fuelVolume: fuelVolumeToSave
        )

        var initialExpenseForNewCar: Expense?

        if selectedCardForExpense == nil && existingExpense == nil {
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
        if carNameValue == nil {
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
