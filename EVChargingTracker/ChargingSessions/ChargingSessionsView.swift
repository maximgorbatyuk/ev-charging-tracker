import SwiftUI

struct ChargingSessionsView: SwiftUICore.View {
    @StateObject private var viewModel = ChargingViewModel()
    @State private var showingAddSession = false
    @ObservedObject private var analytics = AnalyticsService.shared

    var body: some SwiftUICore.View {
        ZStack {
            AppColors.bg
                .ignoresSafeArea()

            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        if let statData = viewModel.statData {
                            StatsBlockView(
                                co2Saved: statData.co2Saved,
                                averageEnergy: statData.avgConsumptionKWhPer100,
                                chargingSessionsCount: statData.totalChargingSessionsCount
                            )
                            .padding(.horizontal)

                            if viewModel.totalCost > 0,
                               let car = viewModel.selectedCarForExpenses {

                                CostsBlockView(
                                    title: L("One kilometer price (charging only)"),
                                    hint: L("How much one kilometer costs you including only charging expenses"),
                                    currency: car.expenseCurrency,
                                    costsValue: statData.oneKmPriceBasedOnlyOnCharging,
                                    perKilometer: true
                                )
                                .padding(.horizontal)

                                CostsBlockView(
                                    title: L("One kilometer price (total)"),
                                    hint: L("How much one kilometer costs you including all logged expenses"),
                                    currency: car.expenseCurrency,
                                    costsValue: statData.oneKmPriceIncludingAllExpenses,
                                    perKilometer: true
                                )
                                .padding(.horizontal)

                                CostsBlockView(
                                    title: L("Total charging costs"),
                                    hint: nil,
                                    currency: car.expenseCurrency,
                                    costsValue: statData.totalChargingCost,
                                    perKilometer: false
                                )
                                .padding(.horizontal)
                            }

                            AppButton(
                                L("Add Charging Session"),
                                kind: .accent,
                                size: .lg,
                                icon: "plus",
                                fullWidth: true,
                                action: { showingAddSession = true }
                            )
                            .padding(.horizontal)

                            if viewModel.expenses.isEmpty {
                                NoExpensesView()
                                    .padding(.top, 60)
                            }

                            // Consumption Trend Chart
                            if let consumptionData = viewModel.consumptionLineChartData {
                                VStack(alignment: .leading, spacing: 0) {
                                    AppSectionHeader(L("Energy per month"))
                                    ChargingConsumptionLineChart(data: consumptionData)
                                        .padding(.horizontal)
                                }
                            }

                            if let expenseData = viewModel.expenseChartData {
                                VStack(alignment: .leading, spacing: 0) {
                                    AppSectionHeader(L("Expenses chart"))
                                    ExpensesChartView(data: expenseData)
                                        .id(expenseData.id)
                                        .padding(.horizontal)
                                }
                            }

                        } else {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1) // make it larger (optional)
                        }
                    } // end of VStack
                    .padding(.vertical)
                } // end of ScrollView
                .scrollContentBackground(.hidden)
                .background(AppColors.bg)
                .navigationTitle(L("Car stats"))
                .navigationBarTitleDisplayMode(.automatic)
                .sheet(isPresented: $showingAddSession) {

                    let selectedCar = viewModel.selectedCarForExpenses
                    let lastChargingSession = viewModel.getLastChargingSessionOrNull(selectedCar)

                    AddExpenseView(
                        defaultExpenseType: .charging,
                        defaultCurrency: viewModel.getAddExpenseCurrency(),
                        selectedCar: selectedCar,
                        allCars: viewModel.getAllCars(),
                        lastChargingSession: lastChargingSession,
                        onAdd: { newExpenseResult in

                            viewModel.saveChargingSession(newExpenseResult)

                            analytics.trackEvent(
                                "charge_session_added",
                                properties: [
                                    "screen": "charging_sessions_stats_screen"
                                ])

                            viewModel.loadSessions()
                        })
                }
                .onAppear {
                    analytics.trackScreen("charging_sessions_stats_screen")
                    viewModel.loadSessions()
                }
                .refreshable {
                    viewModel.loadSessions()
                }

            }
        }
    }
}

#Preview {
    ChargingSessionsView()
}
