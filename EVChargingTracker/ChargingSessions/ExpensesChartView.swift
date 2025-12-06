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
    @StateObject private var viewModel: ExpensesChartViewModel

    init(expenses: [Expense], currency: Currency, analytics: AnalyticsService) {
        self.expenses = expenses
        self.currency = currency

        _viewModel = StateObject(wrappedValue: ExpensesChartViewModel(
            expenses: expenses,
            currency: currency,
            analytics: analytics))
    }

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {

            Text(L("Expenses chart"))
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.bottom, 12)

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
                
                // Custom Legend
                FlowLayout(spacing: 12) {
                    ForEach(viewModel.allExpenseTypes, id: \.self) { type in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForExpenseType(type))
                                .frame(width: 8, height: 8)
                            Text(viewModel.localizedExpenseType(type))
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                        }
                    }
                }
                .padding(.top, 8)

                FilterButtonsView(
                    filterButtons: viewModel.filterButtons)
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
