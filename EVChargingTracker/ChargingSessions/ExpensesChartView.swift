//
//  ExpensesChartView.swift
//  EVChargingTracker
//
//  Created on 06.12.2025.
//

import SwiftUI
import Charts

struct MonthlyExpenseData: Identifiable {
    let id = UUID()
    let month: String
    let date: Date
    let expenseType: ExpenseType
    let amount: Double
}

struct ExpensesChartView: SwiftUICore.View {
    let expenses: [Expense]
    let currency: Currency

    @Environment(\.colorScheme) var colorScheme
    
    private var monthlyExpenseData: [MonthlyExpenseData] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the last 4 months including current month
        var months: [Date] = []
        for i in 0..<4 {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: now) {
                months.append(monthDate)
            }
        }
        months.reverse() // Oldest to newest
        
        // Filter expenses from the last 4 months
        let validExpenses = expenses.filter { expense in
            !expense.isInitialRecord && 
            expense.cost != nil &&
            expense.cost! > 0
        }
        
        // Group expenses by month and type
        var result: [MonthlyExpenseData] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        for monthDate in months {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            
            let monthExpenses = validExpenses.filter { expense in
                expense.date >= monthStart && expense.date <= monthEnd
            }
            
            // Group by expense type for this month
            let groupedByType = Dictionary(grouping: monthExpenses) { $0.expenseType }
            
            let monthName = dateFormatter.string(from: monthDate)
            
            // If there are no expenses for this month, add a zero entry for at least one type
            if groupedByType.isEmpty {
                result.append(MonthlyExpenseData(
                    month: monthName,
                    date: monthDate,
                    expenseType: .charging,
                    amount: 0
                ))
            } else {
                for (type, expensesOfType) in groupedByType {
                    let total = expensesOfType.compactMap { $0.cost }.reduce(0, +)
                    result.append(MonthlyExpenseData(
                        month: monthName,
                        date: monthDate,
                        expenseType: type,
                        amount: total
                    ))
                }
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    private var hasExpenses: Bool {
        monthlyExpenseData.contains { $0.amount > 0 }
    }
    
    private var allExpenseTypes: [ExpenseType] {
        let types = Set(monthlyExpenseData.map { $0.expenseType })
        return Array(types).sorted { type1, type2 in
            // Sort by a custom order for consistent legend
            let order: [ExpenseType] = [.charging, .maintenance, .repair, .carwash, .other]
            let index1 = order.firstIndex(of: type1) ?? order.count
            let index2 = order.firstIndex(of: type2) ?? order.count
            return index1 < index2
        }
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

            if !hasExpenses {
                Text(L("No expenses yet"))
                    .font(.subheadline)
                    .foregroundColor((colorScheme == .dark ? Color.white : Color.primary).opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
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
                
                // Custom Legend
                FlowLayout(spacing: 12) {
                    ForEach(allExpenseTypes, id: \.self) { type in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForExpenseType(type))
                                .frame(width: 8, height: 8)
                            Text(localizedExpenseType(type))
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.1))
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

// MARK: - FlowLayout for Legend
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
                maxX = max(maxX, currentX - spacing)
            }
            
            self.size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}
