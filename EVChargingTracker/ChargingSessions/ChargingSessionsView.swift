import SwiftUI

struct ChargingSessionsView: SwiftUICore.View {
    @StateObject private var viewModel = ChargingViewModel()
    @State private var showingAddSession = false
    @ObservedObject private var analytics = AnalyticsService.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUICore.View {
        ZStack {
            Color.blue
                .ignoresSafeArea()

            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        if (viewModel.statData != nil) {
                            StatsBlockView(
                                co2Saved: viewModel.statData!.co2Saved,
                                averageEnergy: viewModel.statData!.avgConsumptionKWhPer100,
                                chargingSessionsCount: viewModel.statData!.totalChargingSessionsCount
                            )
                            .padding(.horizontal)

                            if viewModel.totalCost > 0 {

                                CostsBlockView(
                                    title: L("One kilometer price (charging only)"),
                                    hint: L("How much one kilometer costs you including only charging expenses"),
                                    currency: viewModel.selectedCarForExpenses!.expenseCurrency,
                                    costsValue: viewModel.statData!.oneKmPriceBasedOnlyOnCharging,
                                    perKilometer: true
                                )

                                CostsBlockView(
                                    title: L("One kilometer price (total)"),
                                    hint: L("How much one kilometer costs you including all logged expenses"),
                                    currency: viewModel.selectedCarForExpenses!.expenseCurrency,
                                    costsValue: viewModel.statData!.oneKmPriceIncludingAllExpenses,
                                    perKilometer: true
                                )

                                CostsBlockView(
                                    title: L("Total charging costs"),
                                    hint: nil,
                                    currency: viewModel.selectedCarForExpenses!.expenseCurrency,
                                    costsValue: viewModel.statData!.totalChargingCost,
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
                                        colors: [Color.orange, Color.red.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .background(.black)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            // Consumption Trend Chart
                            if viewModel.consumptionLineChartData != nil {
                                ChargingConsumptionLineChart(
                                    data: viewModel.consumptionLineChartData!)
                                .padding(.top, 20)
                            }

                            if viewModel.expenseChartData != nil {
                                ExpensesChartView(data: viewModel.expenseChartData!)
                                .padding(.horizontal)
                                .padding(.top, 20)
                            }

                        } else {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1) // make it larger (optional)
                        }
                    } // end of VStack
                    .padding(.vertical)
                } // end of ScrollView
                .navigationTitle(L("Car stats"))
                .navigationBarTitleDisplayMode(.automatic)
                .sheet(isPresented: $showingAddSession) {

                    let selectedCar = viewModel.selectedCarForExpenses
                    AddExpenseView(
                        defaultExpenseType: .charging,
                        defaultCurrency: viewModel.getAddExpenseCurrency(),
                        selectedCar: selectedCar,
                        allCars: viewModel.getAllCars(),
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
