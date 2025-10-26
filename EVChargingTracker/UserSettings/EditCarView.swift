import SwiftUI

struct EditCarView: SwiftUICore.View {
    let car: CarDto
    let onSave: (CarDto) -> Void
    let onCancel: () -> Void

    @ObservedObject private var loc = LocalizationManager.shared

    @State private var name: String
    @State private var batteryText: String
    @State private var mileageText: String
    @State private var selectedForTracking: Bool

    init(
        car: CarDto,
        onSave: @escaping (CarDto) -> Void,
        onCancel: @escaping () -> Void)
    {
        self.car = car
        self.onSave = onSave
        self.onCancel = onCancel

        _name = State(initialValue: car.name)
        _batteryText = State(initialValue: car.batteryCapacity.map { String($0) } ?? "")
        _mileageText = State(initialValue: String(car.currentMileage))
        _selectedForTracking = State(initialValue: car.selectedForTracking)
    }

    var body: some SwiftUICore.View {
        NavigationView {
            Form {
                Section(header: Text(L("Car"))) {
                    TextField(L("Name"), text: $name)
                }

                Section(header: Text(L("Battery capacity (kWh)"))) {
                    TextField(L("e.g. 75"), text: $batteryText)
                        .keyboardType(.numberPad)
                }

                Section(header: Text(L("Current mileage (km)"))) {
                    Text(String(format: L("Minimum: %d"), car.initialMileage))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)

                    TextField(String(format: L("Current: %d"), car.currentMileage), text: $mileageText)
                        .keyboardType(.numberPad)
                }

                Section(header: Text(L("Danger zone"))) {
                    Toggle(L("Selected for tracking"), isOn: $selectedForTracking)
                        .disabled(true)
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

                        var mileageToSave = car.currentMileage
                        let mileage = Int(mileageText) ?? car.currentMileage
                        if (mileage >= car.initialMileage) {
                            mileageToSave = mileage
                        }

                        let updated = CarDto(
                            id: car.id,
                            name: name,
                            selectedForTracking: selectedForTracking,
                            batteryCapacity: batteryToSave,
                            currentMileage: mileageToSave,
                            initialMileage: car.initialMileage
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
            initialMileage: 0),
        onSave: { _ in },
        onCancel: {})
}
