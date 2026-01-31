import SwiftUI

struct EditCarView: SwiftUICore.View {
    let car: CarDto?
    let hasOtherCars: Bool
    let onSave: (CarDto) -> Void
    let onDelete: (CarDto) -> Void
    let onCancel: () -> Void

    @ObservedObject private var loc = LocalizationManager.shared

    @State private var name: String
    @State private var batteryText: String
    @State private var initialMileageText: String
    @State private var mileageText: String
    @State private var expenseCurrency: Currency
    @State private var selectedForTracking: Bool
    @State private var frontWheelSize: String
    @State private var rearWheelSize: String
    @State private var sameWheelSizeForFrontAndRear: Bool

    @State private var showDeleteConfirmation = false
    @State private var alertMessage: String? = nil
    @State private var showingWheelInfoSheet = false

    init(
        car: CarDto?,
        defaultCurrency: Currency,
        defaultValueForSelectedForTracking: Bool,
        hasOtherCars: Bool,
        onSave: @escaping (CarDto) -> Void,
        onDelete: @escaping (CarDto) -> Void,
        onCancel: @escaping () -> Void)
    {
        self.car = car
        self.hasOtherCars = hasOtherCars
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel

        _name = State(initialValue: car?.name ?? "")
        _batteryText = State(initialValue: car?.batteryCapacity.map { String($0) } ?? "")
        _mileageText = State(initialValue: car != nil ? String(car!.currentMileage) : "")
        _initialMileageText = State(initialValue: car != nil ? String(car!.initialMileage) : "")
        _selectedForTracking = State(initialValue: car?.selectedForTracking ?? defaultValueForSelectedForTracking)
        _expenseCurrency = State(initialValue: car?.expenseCurrency ?? defaultCurrency)

        let frontWheel = car?.frontWheelSize ?? ""
        let rearWheel = car?.rearWheelSize ?? ""
        _frontWheelSize = State(initialValue: frontWheel)
        _rearWheelSize = State(initialValue: rearWheel)
        _sameWheelSizeForFrontAndRear = State(initialValue: frontWheel.isEmpty && rearWheel.isEmpty || frontWheel == rearWheel)
    }

    var body: some SwiftUICore.View {
        NavigationView {
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

                    VStack {
                        Toggle(L("Selected for tracking"), isOn: $selectedForTracking)
                            .padding(.bottom, 4)
                            .disabled(!hasOtherCars)

                        Text(L("If you change it, then other active car will be unselected automatically."))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Section(header: Text(L("Wheel details"))) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(L("Front wheel size"))
                                .foregroundColor(.secondary)

                            Button(action: {
                                showingWheelInfoSheet = true
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }

                        TextField(L("e.g. 225/45R18, 20x9.5"), text: $frontWheelSize)
                            .textContentType(.none)
                            .textInputAutocapitalization(.never)

                        Toggle(L("Front = Rear"), isOn: $sameWheelSizeForFrontAndRear)
                            .toggleStyle(SwitchToggleStyle(tint: .orange))

                        if !sameWheelSizeForFrontAndRear {
                            HStack {
                                Text(L("Rear wheel size"))
                                    .foregroundColor(.secondary)

                                Button(action: {
                                    showingWheelInfoSheet = true
                                }) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }

                            TextField(L("e.g. 225/45R18, 20x9.5"), text: $rearWheelSize)
                                .textContentType(.none)
                                .textInputAutocapitalization(.never)
                        }
                    }
                    .onChange(of: sameWheelSizeForFrontAndRear) { _, newValue in
                        if newValue {
                            rearWheelSize = frontWheelSize
                        }
                    }
                    .onChange(of: frontWheelSize) { _, newValue in
                        if sameWheelSizeForFrontAndRear {
                            rearWheelSize = newValue
                        }
                    }
                    .sheet(isPresented: $showingWheelInfoSheet) {
                        WheelInfoSheetView()
                    }
                }

                if (car != nil) {
                    Section(header: Text(L("Danger zone"))) {
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text(L("Delete car"))
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("Edit car"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showDeleteConfirmation) {
                deleteConfirmationAlert()
            }
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
                            batteryToSave = battery
                        }

                        var currentMileageToSave = car?.currentMileage ?? 0
                        var initialMileageToSave = car?.initialMileage ?? 0

                        if (car != nil) {
                            currentMileageToSave = Int(mileageText) ?? car!.currentMileage
                            initialMileageToSave = Int(initialMileageText) ?? car!.initialMileage
                        } else {
                            initialMileageToSave = Int(initialMileageText) ?? 0
                            let currentMileageValue = Int(mileageText) ?? 0

                            if (currentMileageValue >= initialMileageToSave) {
                                currentMileageToSave = currentMileageValue
                            } else {
                                currentMileageToSave = initialMileageToSave
                            }
                        }

                        let selectedForTracking = self.selectedForTracking

                        let frontWheelToSave: String? = frontWheelSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : frontWheelSize.trimmingCharacters(in: .whitespacesAndNewlines)
                        let rearWheelToSave: String? = rearWheelSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : rearWheelSize.trimmingCharacters(in: .whitespacesAndNewlines)

                        let updated = CarDto(
                            id: car?.id,
                            name: name,
                            selectedForTracking: selectedForTracking,
                            batteryCapacity: batteryToSave,
                            currentMileage: currentMileageToSave,
                            initialMileage: initialMileageToSave,
                            expenseCurrency: expenseCurrency,
                            frontWheelSize: frontWheelToSave,
                            rearWheelSize: rearWheelToSave
                        )
                        onSave(updated)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func deleteConfirmationAlert() -> Alert {
        return Alert(
            title: Text(L("Delete car")),
            message: Text(L("Delete selected car? This action cannot be undone.")),
            primaryButton: .destructive(Text(L("Delete"))) {
                onDelete(car!)
                showDeleteConfirmation = false
            },
            secondaryButton: .cancel {
                showDeleteConfirmation = false
            }
        )
    }
}

struct WheelInfoSheetView: SwiftUICore.View {
    @Environment(\.dismiss) var dismiss

    var body: some SwiftUICore.View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L("Wheel Size Formats"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)

                    Text(L("Metric format:"))
                        .font(.headline)
                        .padding(.top, 8)

                    Text(L("Example: 225/45R18"))
                        .font(.subheadline)
                        .padding(.leading, 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("• 225 - Tire width in mm"))
                        Text(L("• 45 - Aspect ratio (height/width %)"))
                        Text(L("• R - Radial construction"))
                        Text(L("• 18 - Rim diameter in inches"))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)

                    Text(L("Imperial format:"))
                        .font(.headline)
                        .padding(.top, 16)

                    Text(L("Example: 20x9.5"))
                        .font(.subheadline)
                        .padding(.leading, 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("• 20 - Rim diameter in inches"))
                        Text(L("• 9.5 - Wheel width in inches"))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                }
                .padding()
            }
            .navigationTitle(L("Wheel Size Info"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Done")) {
                        dismiss()
                    }
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
            expenseCurrency: .usd,
            frontWheelSize: "225/45R18",
            rearWheelSize: "225/45R18"),
        defaultCurrency: .usd,
        defaultValueForSelectedForTracking: true,
        hasOtherCars: true,
        onSave: { _ in },
        onDelete: { _ in },
        onCancel: {})
}
