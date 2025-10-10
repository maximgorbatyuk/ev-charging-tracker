//
//  AddSessionView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 10.10.2025.
//
import SwiftUI

struct AddSessionView: SwiftUICore.View {
    @ObservedObject var viewModel: ChargingViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var date = Date()
    @State private var energyCharged = ""
    @State private var chargerType: ChargerType = .home7kW
    @State private var odometer = ""
    @State private var cost = ""
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var isInitialRecord = false
    
    var body: some SwiftUICore.View {
        NavigationView {
            Form {
                Section(header: Text("Session Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
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
                    
                    HStack {
                        Text("Odometer (km)")
                        Spacer()
                        TextField("12345", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Spacer()
                        Toggle("First record to start tracking?", isOn: $isInitialRecord)
                    }
                }
                
                Section(header: Text("Optional")) {
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("12.50", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Add Session")
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
            .alert("Invalid Input", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter valid values for Energy and Odometer.")
            }
        }
    }
    
    private func saveSession() {
        guard let energy = Double(energyCharged),
              let odo = Int(odometer) else {
            showingAlert = true
            return
        }
        
        let sessionCost = Double(cost)
        
        let session = ChargingSession(
            date: date,
            energyCharged: energy,
            chargerType: chargerType,
            odometer: odo,
            cost: sessionCost,
            notes: notes,
            isInitalRecord: isInitialRecord
        )
        
        viewModel.addSession(session)
        dismiss()
    }
}
