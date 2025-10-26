import SwiftUI

struct ChargingSessionsView: SwiftUICore.View {
    @StateObject private var viewModel = ChargingViewModel()
    @State private var showingAddSession = false
    @ObservedObject private var loc = LocalizationManager.shared

    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {
                
                ScrollView {
                    VStack(spacing: 20) {

                        StatsBlockView(
                            totalEnergy: viewModel.totalEnergy,
                            averageEnergy: viewModel.getAvgConsumptionKWhPer100(),
                            chargingSessionsCount: viewModel.getChargingSessionsCount()
                        )
                        .padding(.horizontal)

                        if viewModel.totalCost > 0 {

                            CostsBlockView(
                                title: L("One kilometer price (charging only)"),
                                hint: L("How much one kilometer costs you including only charging expenses"),
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.calculateOneKilometerCosts(true),
                                perKilometer: true
                            )

                            CostsBlockView(
                                title: L("One kilometer price (total)"),
                                hint: L("How much one kilometer costs you including all logged expenses"),
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.calculateOneKilometerCosts(false),
                                perKilometer: true
                            )

                            CostsBlockView(
                                title: L("Total charging costs"),
                                hint: nil,
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.totalChargingCost,
                                perKilometer: false
                            )
                        }

                        if viewModel.expenses.isEmpty {
                            NoExpensesView()
                                .padding(.top, 60)
                        }

                        Button(action: {
                            showingAddSession = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text(L("Add Charging Session"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(L("Car stats"))
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showingAddSession) {

                let selectedCar = viewModel.selectedCarForExpenses
                AddExpenseView(
                    defaultExpenseType: .charging,
                    defaultCurrency: viewModel.getDefaultCurrency(),
                    selectedCar: selectedCar,
                    onAdd: { newExpenseResult in

                        var carId: Int64? = nil
                        if (selectedCar == nil) {
                            if (newExpenseResult.carName == nil) {

                                // TODO mgorbatyuk: show error alert to user
                                print("Error: First expense must have a car name!")
                                return
                            }

                            let now = Date()
                            let car = Car(
                                id: nil,
                                name: newExpenseResult.carName!,
                                selectedForTracking: true,
                                batteryCapacity: newExpenseResult.batteryCapacity,
                                expenseCurrency: newExpenseResult.initialExpenseForNewCar!.currency,
                                currentMileage: newExpenseResult.initialExpenseForNewCar!.odometer,
                                initialMileage: newExpenseResult.initialExpenseForNewCar!.odometer,
                                milleageSyncedAt: now,
                                createdAt: now)

                            carId = viewModel.addCar(car: car)
                            newExpenseResult.initialExpenseForNewCar!.setCarId(carId!)
                            viewModel.addExpense(newExpenseResult.initialExpenseForNewCar!)
                        } else {
                            carId = selectedCar!.id
                            selectedCar!.updateMileage(newMileage: newExpenseResult.expense.odometer)
                            _ = viewModel.updateMilleage(selectedCar!)
                        }

                        newExpenseResult.expense.setCarId(carId)
                        viewModel.addExpense(newExpenseResult.expense)
                    })
            }
            .onAppear {
                viewModel.loadSessions()
            }
        }
    }
}

#Preview {
    ChargingSessionsView()
}
