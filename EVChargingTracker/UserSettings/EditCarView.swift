import SwiftUI

struct EditCarView: SwiftUICore.View {
    let car: CarDto
    let onSave: (CarDto) -> Void
    let onCancel: () -> Void

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
                Section(header: Text(NSLocalizedString("Car", comment: "Section header for car info"))) {
                    TextField(NSLocalizedString("Name", comment: "Placeholder for car name"), text: $name)
                }

                Section(header: Text(NSLocalizedString("Battery capacity (kWh)", comment: "Section header for battery capacity"))) {
                    TextField(NSLocalizedString("e.g. 75", comment: "Placeholder example for battery capacity"), text: $batteryText)
                        .keyboardType(.numberPad)
                }

                Section(header: Text(NSLocalizedString("Current mileage (km)", comment: "Section header for current mileage"))) {
                    Text(String(format: NSLocalizedString("Minimum: %d", comment: "Label showing minimum allowed mileage"), car.initialMileage))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)

                    TextField(String(format: NSLocalizedString("Current: %d", comment: "Placeholder showing current mileage"), car.currentMileage), text: $mileageText)
                        .keyboardType(.numberPad)
                }

                Section(header: Text(NSLocalizedString("Danger zone", comment: "Section header for dangerous settings"))) {
                    Toggle(NSLocalizedString("Selected for tracking", comment: "Toggle label for selected for tracking"), isOn: $selectedForTracking)
                        .disabled(true)
                }
            }
            .navigationTitle(NSLocalizedString("Edit car", comment: "Navigation title for edit car screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "Save button")) {
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
