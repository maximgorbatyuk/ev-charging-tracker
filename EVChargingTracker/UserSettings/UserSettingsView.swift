//
//  UserSettingsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

import SwiftUI

struct UserSettingsView: SwiftUICore.View {

    @StateObject private var viewModel = UserSettingsViewModel()
    @State private var showEditCurrencyModal: Bool = false
    @State private var editingCar: CarDto? = nil
    @State private var _cars: [CarDto]? = nil

    // Make this a computed property so it can access `viewModel` safely
    private var cars: [CarDto] {
        if (_cars == nil) {
            self._cars = viewModel.getCars()
        }

        return _cars ?? []
    }

    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {

                ScrollView {
                    VStack(alignment: .leading) {

                        Section(header: Text("Base settings")) {
                            Spacer()
                            HStack {
                                Text("Currency")
                                    .fontWeight(.semibold)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gray)

                                Spacer()

                                if (!viewModel.hasAnyExpense()) {
                                    Button(action: {
                                        showEditCurrencyModal = true
                                    }) {
                                        Text("\(String(describing: viewModel.defaultCurrency).uppercased()) (\(viewModel.defaultCurrency.rawValue))")
                                            .fontWeight(.semibold)
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                } else {
                                    Text("\(String(describing: viewModel.defaultCurrency).uppercased()) (\(viewModel.defaultCurrency.rawValue))")
                                        .fontWeight(.semibold)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gray)
                                }
                            }

                            Text("It is recommended to set the default currency before adding any expenses.")
                                .fontWeight(.semibold)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                                .padding(.top)
                        }

                        Divider()
                        Spacer()

                        if (viewModel.getCarsCount() > 0) {
                            Section(header: Text("Cars")) {
                                Spacer()
                                VStack(alignment: .leading) {
                                    ForEach(cars) { car in
                                        CarRecordView(
                                            car: car,
                                            onEdit: {
                                                editingCar = car
                                            })
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("User settings")
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showEditCurrencyModal) {
                EditDefaultCurrencyView(
                    selectedCurrency: viewModel.getDefaultCurrency(),
                    onSave: { newCurrency in
                        viewModel.saveDefaultCurrency(newCurrency)
                    })
            }
            .sheet(item: $editingCar) { car in
                EditCarView(
                    car: car,
                    onSave: { updated in
                        
                        if updated.name.trimmingCharacters(in: .whitespaces).isEmpty {
                            // TODO mgorbatyuk: show alert
                            return
                        }

                        if (updated.batteryCapacity != nil &&
                            updated.batteryCapacity! < 0){
                            // TODO mgorbatyuk: show alert
                            return
                        }

                        let carToUpdate = viewModel.getCarById(car.id)
                        if (carToUpdate == nil) {
                            // TODO mgorbatyuk: alert that car was not found
                            return
                        }

                        carToUpdate!.updateValues(
                            name: updated.name,
                            batteryCapacity: updated.batteryCapacity,
                            currentMileage: updated.currentMileage)

                        _ = viewModel.updateCar(car: carToUpdate!)

                        editingCar = nil
                    },
                    onCancel: {
                        editingCar = nil
                    }
                )
            }
            .onAppear {
                self._cars = viewModel.getCars()
            }
        }
    }
}

#Preview {
    UserSettingsView()
}
