import SwiftUI

struct EditCarView: SwiftUICore.View {
    let car: CarDto?
    let onSave: (CarDto) -> Void
    let onCancel: () -> Void

    @ObservedObject private var loc = LocalizationManager.shared

    @State private var name: String
    @State private var batteryText: String
    @State private var initialMileageText: String
    @State private var mileageText: String
    @State private var expenseCurrency: Currency
    @State private var selectedForTracking: Bool

    init(
        car: CarDto?,
        defaultCurrency: Currency,
        defaultValueForSelectedForTracking: Bool,
        onSave: @escaping (CarDto) -> Void,
        onCancel: @escaping () -> Void)
    {
        self.car = car
        self.onSave = onSave
        self.onCancel = onCancel

        _name = State(initialValue: car?.name ?? "")
        _batteryText = State(initialValue: car?.batteryCapacity.map { String($0) } ?? "")
        _mileageText = State(initialValue: car != nil ? String(car!.currentMileage) : "")
        _initialMileageText = State(initialValue: car != nil ? String(car!.initialMileage) : "")
        _selectedForTracking = State(initialValue: car?.selectedForTracking ?? defaultValueForSelectedForTracking)
        _expenseCurrency = State(initialValue: car?.expenseCurrency ?? defaultCurrency)
    }

    var body: some SwiftUICore.View {
        NavigationView {
            Form {
                Section(header: Text(L("Basic info"))) {
                    HStack {
                        Text(L("Name"))
                            .foregroundColor(.secondary)

                        Spacer()
                        TextField(L("Car name"), text: $name)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text(L("Battery capacity (kWh)"))
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField(L("e.g. 75"), text: $batteryText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker(L("Select currency"), selection: $expenseCurrency) {
                        ForEach(Currency.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                }

                Section(header: Text(L("Car mileage"))) {
                    
                    HStack {
                        Text(L("Initial (km)"))
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("", text: $initialMileageText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text(L("Current (km)"))
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("", text: $mileageText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text(L("Danger zone"))) {
                    Toggle(L("Selected for tracking"), isOn: $selectedForTracking)
                }
            }
            .navigationTitle(L("Edit car"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        let battery = Double(batteryText)
                        
                        var batteryToSave: Double? = nil
                        if (battery != nil && battery! <= 200) {
                            // realistic battery capacity
                            batteryToSave = battery
                        }

                        var mileageToSave = car?.currentMileage ?? 0
                        var initialMileageToSave = car?.initialMileage ?? 0

                        let mileage = Int(mileageText) ?? car?.currentMileage ?? 0
                        if (mileage >= initialMileageToSave) {
                            mileageToSave = mileage
                        }

                        let initialMileage = Int(initialMileageText) ?? car?.initialMileage ?? 0
                        if (initialMileage <= mileageToSave) {
                            initialMileageToSave = initialMileage
                        }

                        let selectedForTracking = self.selectedForTracking

                        let updated = CarDto(
                            id: car?.id,
                            name: name,
                            selectedForTracking: selectedForTracking,
                            batteryCapacity: batteryToSave,
                            currentMileage: mileageToSave,
                            initialMileage: initialMileageToSave,
                            expenseCurrency: expenseCurrency
                        )
                        onSave(updated)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    EditCarView(
        car: CarDto(
            id: 1,
            name: "My car",
            selectedForTracking: true,
            batteryCapacity: 75.5,
            currentMileage: 12345,
            initialMileage: 0,
            expenseCurrency: .usd),
        defaultCurrency: .usd,
        defaultValueForSelectedForTracking: true,
        onSave: { _ in },
        onCancel: {})
}
