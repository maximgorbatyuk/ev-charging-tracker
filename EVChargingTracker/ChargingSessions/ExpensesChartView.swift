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

    @Environment(\.colorScheme) var colorScheme
    
    private var expensesByType: [(type: ExpenseType, total: Double)] {
        let grouped = Dictionary(grouping: expenses.filter { !$0.isInitialRecord && $0.cost != nil }) { $0.expenseType }
        
        return grouped.map { (type, expenses) in
            let total = expenses.compactMap { $0.cost }.reduce(0, +)
            return (type: type, total: total)
        }
        .filter { $0.total > 0 }
        .sorted { $0.total > $1.total }
    }

    private func localizedExpenseType(_ type: ExpenseType) -> String {
        switch type {
        case .charging:
            return L("Filter.Charges")
        case .maintenance, .repair:
            return L("Filter.Repair/maintenance")
        case .carwash:
            return L("Filter.Carwash")
        case .other:
            return L("Other")
        }
    }

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("Expenses"))
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)

            if expensesByType.isEmpty {
                Text(L("No expenses yet"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(expensesByType, id: \.type) { item in
                    BarMark(
                        x: .value(L("Expense type"), localizedExpenseType(item.type)),
                        y: .value(L("Cost"), item.total)
                    )
                    .foregroundStyle(colorForExpenseType(item.type))
                    .annotation(position: .top) {
                        Text(String(format: "%.2f", item.total))
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
                
                // Legend
                HStack(spacing: 16) {
                    ForEach(expensesByType, id: \.type) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForExpenseType(item.type))
                                .frame(width: 8, height: 8)
                            Text(localizedExpenseType(item.type))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }

    private func colorForExpenseType(_ type: ExpenseType) -> Color {
        switch type {
        case .charging:
            return .green
        case .maintenance, .repair:
            return .orange
        case .carwash:
            return .blue
        case .other:
            return .purple
        }
    }
}
