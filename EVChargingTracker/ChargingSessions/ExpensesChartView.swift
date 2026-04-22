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

    @StateObject var viewModel: ExpensesChartViewModel

    init(data: ExpensesChartData) {
        self.data = data

        _viewModel = StateObject(wrappedValue: ExpensesChartViewModel(
            expenses: data.expenses,
            currency: data.currency,
            analytics: data.analytics,
            monthsCount: data.monthsCount))
    }

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {
            AppCard(pad: 0) {
                if viewModel.hasChartItemsToShow {
                    Chart {
                        ForEach(viewModel.monthlyExpenseData) { item in
                            BarMark(
                                x: .value(L("Date"), item.month),
                                y: .value(L("Cost"), item.amount),
                                stacking: .standard
                            )
                            .foregroundStyle(item.expenseType.color)
                            .cornerRadius(4)
                        }
                    }
                    .frame(height: 280)
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .foregroundStyle(AppColors.inkSoft)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(AppColors.inkSoft)
                        }
                    }
                    .chartLegend(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                } else {
                    VStack {
                        Spacer()

                        Image(systemName: "chart.bar.xaxis")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .foregroundColor(AppColors.inkGhost)
                            .padding(.horizontal)

                        Text(L("No expense data available for the selected filter."))
                            .foregroundColor(AppColors.inkSoft)
                            .appFont(.custom(size: 14), weight: .semibold)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                            .padding(.horizontal)

                        Spacer()
                    }
                    .frame(height: 280)
                    .frame(maxWidth: .infinity, maxHeight: 280)
                }
            }

            FilterButtonsView(filterButtons: viewModel.filterButtons)

            if !viewModel.allExpenseTypes.isEmpty {
                legend
            }
        }
    }

    @ViewBuilder
    private var legend: some SwiftUICore.View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ],
            alignment: .leading,
            spacing: 6
        ) {
            ForEach(viewModel.allExpenseTypes, id: \.self) { type in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(type.color)
                        .frame(width: 10, height: 10)
                    Text(type.localizedName)
                        .appFont(.caption2)
                        .foregroundColor(AppColors.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
}
