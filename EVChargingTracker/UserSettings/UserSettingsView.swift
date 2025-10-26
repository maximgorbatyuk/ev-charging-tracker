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

    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {

                ScrollView {
                    VStack(alignment: .leading) {

                        Section(header: Text(NSLocalizedString("Base settings", comment: "Section header for base settings"))) {
                            Spacer()
                            HStack {
                                Text(NSLocalizedString("Currency", comment: "Label for currency"))
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

                            Text(NSLocalizedString("It is recommended to set the default currency before adding any expenses.", comment: "Recommendation to set default currency"))
                                .fontWeight(.semibold)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                                .padding(.top)
                        }

                        Divider()
                        Spacer()

                        if (viewModel.getCarsCount() > 0) {
                            Section(header: Text(NSLocalizedString("Cars", comment: "Section header for cars"))) {
                                Spacer()
                                VStack(alignment: .leading) {
                                    ForEach(viewModel.allCars) { car in
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
            .navigationTitle(NSLocalizedString("User settings", comment: "Navigation title for user settings"))
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

                        if let batteryCapacity = updated.batteryCapacity, batteryCapacity < 0 {
                            // TODO mgorbatyuk: show alert
                            return
                        }

                        guard let carToUpdate = viewModel.getCarById(car.id) else {
                            // TODO mgorbatyuk: alert that car was not found
                            return
                        }

                        carToUpdate.updateValues(
                            name: updated.name,
                            batteryCapacity: updated.batteryCapacity,
                            currentMileage: updated.currentMileage)

                        _ = viewModel.updateCar(car: carToUpdate)

                        editingCar = nil
                        viewModel.refetchCars()
                    },
                    onCancel: {
                        editingCar = nil
                    }
                )
            }
            .onAppear {
                viewModel.refetchCars()
            }
        }
    }
}

#Preview {
    UserSettingsView()
}
