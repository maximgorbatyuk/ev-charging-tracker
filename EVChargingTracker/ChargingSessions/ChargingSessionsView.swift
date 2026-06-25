import SwiftUI

struct ChargingSessionsView: SwiftUICore.View {
    @StateObject private var viewModel = ChargingViewModel()
    @State private var showingAddSession = false
    @ObservedObject private var analytics = AnalyticsService.shared
    @ObservedObject private var distanceCostBasisManager = DistanceCostBasisManager.shared

    var body: some SwiftUICore.View {
        ZStack {
            AppColors.bg
                .ignoresSafeArea()

            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        if let statData = viewModel.statData {
                            let unit = viewModel.selectedCarForExpenses?.measurementSystem ?? .metric
                            StatsBlockView(
                                co2Saved: statData.co2Saved,
                                averageEnergy: statData.avgConsumptionKWhPer100,
                                chargingSessionsCount: statData.totalChargingSessionsCount,
                                measurementSystem: unit
                            )
                            .padding(.horizontal)

                            if viewModel.totalCost > 0,
                               let car = viewModel.selectedCarForExpenses {

                                let basis = distanceCostBasisManager.currentBasis

                                CostsBlockView(
                                    title: perDistancePriceTitle(unit: car.measurementSystem, basis: basis, chargingOnly: true),
                                    hint: perDistancePriceHint(unit: car.measurementSystem, basis: basis, chargingOnly: true),
                                    currency: car.expenseCurrency,
                                    costsValue: statData.oneKmPriceBasedOnlyOnCharging * basis.multiplier,
                                    perKilometer: true,
                                    measurementSystem: car.measurementSystem,
                                    distanceCostBasis: basis
                                )
                                .padding(.horizontal)

                                CostsBlockView(
                                    title: perDistancePriceTitle(unit: car.measurementSystem, basis: basis, chargingOnly: false),
                                    hint: perDistancePriceHint(unit: car.measurementSystem, basis: basis, chargingOnly: false),
                                    currency: car.expenseCurrency,
                                    costsValue: statData.oneKmPriceIncludingAllExpenses * basis.multiplier,
                                    perKilometer: true,
                                    measurementSystem: car.measurementSystem,
                                    distanceCostBasis: basis
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
                                viewModel.selectedCarForExpenses?.carType == .hybrid
                                    ? L("Add charge/fuel")
                                    : L("Add Charging Session"),
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
                    let lastFuelSession = viewModel.getLastFuelSessionOrNull(selectedCar)

                    AddExpenseView(
                        defaultExpenseType: .charging,
                        defaultCurrency: viewModel.getAddExpenseCurrency(),
                        selectedCar: selectedCar,
                        allCars: viewModel.getAllCars(),
                        lastChargingSession: lastChargingSession,
                        lastFuelSession: lastFuelSession,
                        onAdd: { newExpenseResult in

                            viewModel.saveChargingSession(newExpenseResult)

                            let addedEventName = newExpenseResult.expense.expenseType == .fuel
                                ? "fuel_session_added"
                                : "charge_session_added"
                            analytics.trackEvent(
                                addedEventName,
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

    /// Title for a per-distance price card, varying by unit and selected basis.
    private func perDistancePriceTitle(unit: MeasurementSystem, basis: DistanceCostBasis, chargingOnly: Bool) -> String {
        switch (unit, basis) {
        case (.metric, .perUnit):
            return chargingOnly
                ? L("One kilometer price (charging only)")
                : L("One kilometer price (total)")
        case (.metric, .perHundredUnits):
            return chargingOnly
                ? L("100 kilometers price (charging only)")
                : L("100 kilometers price (total)")
        case (.imperial, .perUnit):
            return chargingOnly
                ? L("One mile price (charging only)")
                : L("One mile price (total)")
        case (.imperial, .perHundredUnits):
            return chargingOnly
                ? L("100 miles price (charging only)")
                : L("100 miles price (total)")
        }
    }

    /// Hint shown behind the info icon, varying by unit and selected basis.
    private func perDistancePriceHint(unit: MeasurementSystem, basis: DistanceCostBasis, chargingOnly: Bool) -> String {
        let base: String
        switch (unit, basis) {
        case (.metric, .perUnit):
            base = chargingOnly
                ? L("How much one kilometer costs you including only charging expenses")
                : L("How much one kilometer costs you including all logged expenses")
        case (.metric, .perHundredUnits):
            base = chargingOnly
                ? L("How much 100 kilometers cost you including only charging expenses")
                : L("How much 100 kilometers cost you including all logged expenses")
        case (.imperial, .perUnit):
            base = chargingOnly
                ? L("How much one mile costs you including only charging expenses")
                : L("How much one mile costs you including all logged expenses")
        case (.imperial, .perHundredUnits):
            base = chargingOnly
                ? L("How much 100 miles cost you including only charging expenses")
                : L("How much 100 miles cost you including all logged expenses")
        }

        return base
    }
}

#Preview {
    ChargingSessionsView()
}
