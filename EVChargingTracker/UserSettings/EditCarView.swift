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
                Section(header: Text("Car")) {
                    TextField("Name", text: $name)
                }

                Section(header: Text("Battery capacity (kWh)")) {
                    TextField("e.g. 75", text: $batteryText)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Current mileage (km)")) {
                    Text("Minimum: \(car.initialMileage)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)

                    TextField("Current: \(car.currentMileage)", text: $mileageText)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Danger zone")) {
                    Toggle("Selected for tracking", isOn: $selectedForTracking)
                        .disabled(true)
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
                        let battery = Double(batteryText)
                        
                        var batteryToSave : Double? = nil
                        if (battery != nil && battery! <= 200) {
                            // unrealistic battery capacity
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
