import SwiftUI

struct EditCarView: SwiftUICore.View {
    let car: CarDto
    let onSave: (CarDto) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var batteryText: String
    @State private var mileageText: String

    init(car: CarDto, onSave: @escaping (CarDto) -> Void, onCancel: @escaping () -> Void) {
        self.car = car
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: car.name)
        _batteryText = State(initialValue: car.batteryCapacity.map { String($0) } ?? "")
        _mileageText = State(initialValue: String(car.currentMileage))
    }

    var body: some SwiftUICore.View {
        NavigationView {
            Form {
                Section(header: Text("Car")) {
                    TextField("Name", text: $name)
                }

                Section(header: Text("Battery capacity (kWh)")) {
                    TextField("e.g. 75.0", text: $batteryText)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Current mileage (km)")) {
                    TextField("e.g. 12000", text: $mileageText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // parse values
                        let battery = Double(batteryText)
                        let mileage = Int(mileageText) ?? car.currentMileage

                        let updated = CarDto(
                            id: car.id,
                            name: name,
                            selectedForTracking: car.selectedForTracking,
                            batteryCapacity: battery,
                            currentMileage: mileage,
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
    EditCarView(car: CarDto(id: 1, name: "My car", selectedForTracking: true, batteryCapacity: 75.5, currentMileage: 12345, initialMileage: 0), onSave: { _ in }, onCancel: {})
}
