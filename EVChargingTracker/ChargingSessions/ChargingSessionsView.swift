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
                                title: "How much one kilometer costs you (charging only)",
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.calculateOneKilometerCosts(true),
                                perKilometer: true
                            )

                            CostsBlockView(
                                title: "How much one kilometer costs you (total)",
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.calculateOneKilometerCosts(false),
                                perKilometer: true
                            )

                            CostsBlockView(
                                title: "Total charging costs",
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.totalCost,
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
                                Text("Add Charging Session")
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
            .navigationTitle("Charging stats")
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showingAddSession) {

                let selectedCar = viewModel.selectedCarForExpenses
                AddExpenseView(
                    defaultExpenseType: .charging,
                    defaultCurrency: viewModel.getDefaultCurrency(),
                    showFirstTrackingRecordToggle: viewModel.expenses.isEmpty,
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
                                name: newExpenseResult.carName!,
                                selectedForTracking: true,
                                batteryCapacity: nil,
                                expenseCurrency: newExpenseResult.expense.currency,
                                currentMileage: newExpenseResult.expense.odometer,
                                initialMileage: newExpenseResult.expense.odometer,
                                milleageSyncedAt: now,
                                createdAt: now)

                            carId = viewModel.addCar(car: car)
                        } else {
                            carId = selectedCar!.id
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
