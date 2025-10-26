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
    @ObservedObject private var loc = LocalizationManager.shared

    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {

                ScrollView {
                    VStack(alignment: .leading) {

                        Section(header: Text(L("Base settings"))) {
                            Spacer()
                            HStack {
                                Text(L("Currency"))
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

                            // Language selector row
                            HStack {
                                Text(L("Language"))
                                    .fontWeight(.semibold)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gray)

                                Spacer()

                                Picker(selection: $viewModel.selectedLanguage, label: Text(viewModel.selectedLanguage.displayName)) {
                                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                                        Text(lang.displayName).tag(lang)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: viewModel.selectedLanguage) { _, newLang in
                                    viewModel.saveLanguage(newLang)
                                }
                            }

                            Text(L("It is recommended to set the default currency before adding any expenses."))
                                .fontWeight(.semibold)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                                .padding(.top)
                        }

                        Divider()
                        Spacer()

                        if (viewModel.getCarsCount() > 0) {
                            Section(header: Text(L("Cars"))) {
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
            .navigationTitle(L("User settings"))
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
