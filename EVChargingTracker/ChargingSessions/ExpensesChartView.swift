//
//  ExpensesChartView.swift
//  EVChargingTracker
//
//  Created on 06.12.2025.
//

import SwiftUI
import Charts

struct ExpensesChartView: SwiftUICore.View {
    let expenses: [Expense]
    let currency: Currency
    let monthsCount: Int

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: ExpensesChartViewModel

    init(expenses: [Expense], currency: Currency, analytics: AnalyticsService, monthsCount: Int) {
        self.expenses = expenses
        self.currency = currency
        self.monthsCount = monthsCount

        _viewModel = StateObject(wrappedValue: ExpensesChartViewModel(
            expenses: expenses,
            currency: currency,
            analytics: analytics,
            monthsCount: monthsCount))
    }

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Expenses chart"))
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.hasExpenses {
                    Text(L("No expenses yet"))
                        .font(.subheadline)
                        .foregroundColor((colorScheme == .dark ? Color.white : Color.primary).opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {

                    Chart {
                        ForEach(viewModel.monthlyExpenseData) { item in
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

                    FilterButtonsView(
                        filterButtons: viewModel.filterButtons)
                    .padding(.top, 8)
                }
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
