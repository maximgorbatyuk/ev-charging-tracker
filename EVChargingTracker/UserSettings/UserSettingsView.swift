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

    // Make this a computed property so it can access `viewModel` safely
    private var cars: [CarDto] {
        return viewModel.getCars()
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
                                            car: CarDto(
                                                id: car.id ?? 0,
                                                name: car.name,
                                                selectedForTracking: car.selectedForTracking,
                                                batteryCapacity: car.batteryCapacity,
                                                currentMileage: car.currentMileage,
                                                initialMileage: car.initialMileage,
                                            ),
                                            onDelete: {
                                                // do nothing
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
        }
    }
}

#Preview {
    UserSettingsView()
}
