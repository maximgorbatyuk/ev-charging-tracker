//
//  ExpensesChartView.swift
//  EVChargingTracker
//
//  Created on 06.12.2025.
//

import SwiftUI
import Charts

struct ExpensesChartView: SwiftUICore.View {
    let data: ExpensesChartData
    
    let expenses: [Expense]
    let currency: Currency
    let monthsCount: Int

    var monthlyExpenseData: [MonthlyExpenseData] {
        return viewModel.monthlyExpenseData
    }

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: ExpensesChartViewModel

    init(data: ExpensesChartData) {
        self.data = data
        self.expenses = data.expenses
        self.currency = data.currency
        self.monthsCount = data.monthsCount

        _viewModel = StateObject(wrappedValue: ExpensesChartViewModel(
            expenses: data.expenses,
            currency: data.currency,
            analytics: data.analytics,
            monthsCount: data.monthsCount))
    }

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Expenses chart"))
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                if viewModel.hasChartItemsToShow {
                    Chart {
                        ForEach(monthlyExpenseData) { item in
                            BarMark(
                                x: .value(L("Date"), item.month),
                                y: .value(L("Cost"), item.amount),
                                stacking: .standard
                            )
                            .foregroundStyle(colorForExpenseType(item.expenseType))
                        }
                    }
                    .frame(height: 280)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                                .foregroundStyle((colorScheme == .dark ? Color.white : Color.primary).opacity(0.2))
                            AxisValueLabel()
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        }
                    }
                    .chartLegend(.hidden) // Hide the automatic legend
                }
                else {
                    VStack(alignment: .center) {
                        Image(systemName: "chart.bar.xaxis")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .foregroundColor(.gray.opacity(0.2))
                            .padding(.top, 80)
                            .padding(.horizontal)

                        Text(L("No expense data available for the selected filters."))
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.top, 20)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .frame(height: 280)
                }

                FilterButtonsView(
                    filterButtons: viewModel.filterButtons)
                .padding(.top, 8)
            }
            .padding()
            .background(
                ShadowBackgroundView()
            )
        }
    }

    private func colorForExpenseType(_ type: ExpenseType) -> Color {
        let opacity: Double = colorScheme == .dark ? 0.7 : 0.9
        switch type {
        case .charging:
            return .yellow.opacity(opacity)
        case .maintenance:
            return .green.opacity(opacity)
        case .repair:
            return .orange.opacity(opacity)
        case .carwash:
            return .blue.opacity(opacity)
        case .other:
            return .purple.opacity(opacity)
        }
    }
}
