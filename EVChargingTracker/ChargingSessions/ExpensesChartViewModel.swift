//
//  ExpensesChartViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 06.12.2025.
//

import Foundation
import SwiftUI

@MainActor
class ExpensesChartViewModel: ObservableObject {
    static let ScreenName = "expenses_chart_screen"

    let expenses: [Expense]
    let currency: Currency
    let monthsCount: Int

    private let analytics: AnalyticsService

    var expensesToShow: [Expense]
    @Published var filterButtons: [FilterButtonItem] = []
    @Published var monthlyExpenseData: [MonthlyExpenseData]
    @Published var hasChartItemsToShow: Bool

    init(expenses: [Expense], currency: Currency, analytics: AnalyticsService, monthsCount: Int) {
        self.expenses = expenses
        self.currency = currency
        self.analytics = analytics
        self.monthsCount = monthsCount

        self.expensesToShow = ExpensesChartViewModel.createExpensesToShow(
            filter: nil,
            expenses: expenses)

        let monthlyExpenseData = MonthlyExpenseData.buildCollection(
            countOfBars: monthsCount,
            expensesToShow: self.expensesToShow
        )

        self.monthlyExpenseData = monthlyExpenseData
        self.hasChartItemsToShow = monthlyExpenseData.contains { $0.amount > 0 }

        self.filterButtons = [
            FilterButtonItem(
                title: L("Filter.All"),
                innerAction: { [weak self] in
                    self?.recreateExpensesToShow(nil)
                    self?.analytics.trackEvent(
                        "expenses_chart_filter_all_selected",
                        properties: [
                            "screen": ExpensesChartViewModel.ScreenName
                        ])
                },
                isSelected: true),

            FilterButtonItem(
                title: L("Filter.Charges"),
                innerAction: { [weak self] in
                    self?.recreateExpensesToShow(ExpenseType.charging)
                    self?.analytics.trackEvent(
                        "expenses_chart_filter_charges_selected",
                        properties: [
                            "screen": ExpensesChartViewModel.ScreenName
                        ])
                },
                customColor: ExpenseType.charging.color,
                isSelected: false),

            FilterButtonItem(
                title: L("Filter.Repair"),
                innerAction: { [weak self] in
                    self?.recreateExpensesToShow(ExpenseType.repair)
                    self?.analytics.trackEvent(
                        "expenses_chart_filter_repair_selected",
                        properties: [
                            "screen": ExpensesChartViewModel.ScreenName
                        ])
                },
                customColor: ExpenseType.repair.color,
                isSelected: false),

            FilterButtonItem(
                title: L("Filter.Maintenance"),
                innerAction: { [weak self] in
                    self?.recreateExpensesToShow(ExpenseType.maintenance)
                    self?.analytics.trackEvent(
                        "expenses_chart_filter_maintenance_selected",
                        properties: [
                            "screen": ExpensesChartViewModel.ScreenName
                        ])
                },
                customColor: ExpenseType.maintenance.color,
                isSelected: false),

            FilterButtonItem(
                title: L("Filter.Carwash"),
                innerAction: { [weak self] in
                    self?.recreateExpensesToShow(ExpenseType.carwash)
                    self?.analytics.trackEvent(
                        "expenses_chart_filter_carwash_selected",
                        properties: [
                            "screen": ExpensesChartViewModel.ScreenName
                        ])
                },
                customColor: ExpenseType.carwash.color,
                isSelected: false),

            FilterButtonItem(
                title: L("Filter.Other"),
                innerAction: { [weak self] in
                    self?.recreateExpensesToShow(ExpenseType.other)
                    self?.analytics.trackEvent(
                        "expenses_chart_filter_other_selected",
                        properties: [
                            "screen": ExpensesChartViewModel.ScreenName
                        ])
                },
                customColor: ExpenseType.other.color,
                isSelected: false)
        ]
    }

    private static func createExpensesToShow(
        filter: ExpenseType?,
        expenses: [Expense]) -> [Expense] {

        var expensesToShow = expenses.filter { expense in
            !expense.isInitialRecord &&
            expense.cost != nil &&
            expense.cost! > 0
        }

        if filter == nil {
            return expensesToShow
        }

        expensesToShow = expensesToShow.filter { x in
            x.expenseType == filter!
        }

        return expensesToShow
    }

    func recreateExpensesToShow(_ filter: ExpenseType?) {

        self.expensesToShow = ExpensesChartViewModel.createExpensesToShow(
            filter: filter,
            expenses: expenses)

        self.monthlyExpenseData = MonthlyExpenseData.buildCollection(
            countOfBars: monthsCount,
            expensesToShow: self.expensesToShow
        )

        self.hasChartItemsToShow = self.monthlyExpenseData.contains { $0.amount > 0 }
    }

    var hasExpenses: Bool {
        monthlyExpenseData.contains { $0.amount > 0 }
    }

    var allExpenseTypes: [ExpenseType] {
        let types = Set(monthlyExpenseData.map { $0.expenseType })
        return Array(types).sorted { type1, type2 in
            // Sort by a custom order for consistent legend
            let order: [ExpenseType] = [.charging, .maintenance, .repair, .carwash, .other]
            let index1 = order.firstIndex(of: type1) ?? order.count
            let index2 = order.firstIndex(of: type2) ?? order.count
            return index1 < index2
        }
    }

}

struct MonthlyExpenseData: Identifiable {
    let id = UUID()
    let month: String
    let date: Date
    let expenseType: ExpenseType
    let amount: Double

    static func buildCollection(countOfBars: Int, expensesToShow: [Expense]) -> [MonthlyExpenseData] {
        let calendar = Calendar.current
        let now = Date()

        // Get the last 6 months including current month
        var months: [Date] = []
        for i in 0..<countOfBars {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: now) {
                months.append(monthDate)
            }
        }

        months.reverse() // Oldest to newest

        // Group expenses by month and type
        var result: [MonthlyExpenseData] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"

        for monthDate in months {
            guard
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
                let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                continue
            }

            let monthExpenses = expensesToShow.filter { expense in
                expense.date >= monthStart && expense.date < nextMonthStart
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
                    result.append(
                        MonthlyExpenseData(
                            month: monthName,
                            date: monthDate,
                            expenseType: type,
                            amount: total))
                }
            }
        }

        return result.sorted { $0.date < $1.date }
    }

}
