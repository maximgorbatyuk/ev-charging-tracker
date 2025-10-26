import SwiftUI

struct ChargingSessionsView: SwiftUICore.View {
    @StateObject private var viewModel = ChargingViewModel()
    @State private var showingAddSession = false

    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {
                
                ScrollView {
                    VStack(spacing: 20) {

                        StatsBlockView(
                            totalEnergy: viewModel.totalEnergy,
                            averageEnergy: viewModel.averageEnergy,
                            chargingSessionsCount: viewModel.getChargingSessionsCount()
                        )
                        .padding(.horizontal)

                        if viewModel.totalCost > 0 {

                            CostsBlockView(
                                title: NSLocalizedString("One kilometer price (charging only)", comment: "Title for per-km cost (charging only)"),
                                hint: NSLocalizedString("How much one kilometer costs you including only charging expenses", comment: "Hint explaining per-km charging-only calculation"),
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.calculateOneKilometerCosts(true),
                                perKilometer: true
                            )

                            CostsBlockView(
                                title: NSLocalizedString("One kilometer price (total)", comment: "Title for per-km cost (total)"),
                                hint: NSLocalizedString("How much one kilometer costs you including all logged expenses", comment: "Hint explaining per-km total calculation"),
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.calculateOneKilometerCosts(false),
                                perKilometer: true
                            )

                            CostsBlockView(
                                title: NSLocalizedString("Total charging costs", comment: "Title for total charging costs"),
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
                                Text(NSLocalizedString("Add Charging Session", comment: "Button title to add a charging session"))
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
            .navigationTitle(NSLocalizedString("Charging stats", comment: "Navigation title for charging stats screen"))
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
