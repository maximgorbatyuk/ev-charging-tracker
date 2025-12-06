//
//  ExpensesChartViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 06.12.2025.
//

import Foundation

class ExpensesChartViewModel: ObservableObject {
    static let CountOfBars = 6

    let expenses: [Expense]
    let currency: Currency

    var filterButtons: [FilterButtonItem] = []
    var expensesToShow: [Expense]
    var monthlyExpenseData: [MonthlyExpenseData]

    init(expenses: [Expense], currency: Currency) {
        self.expenses = expenses
        self.currency = currency
        self.expensesToShow = ExpensesChartViewModel.createExpensesToShow(
            filter: nil,
            expenses: expenses)

        self.monthlyExpenseData = MonthlyExpenseData.buildCollection(
            countOfBars: ExpensesChartViewModel.CountOfBars,
            expensesToShow: self.expensesToShow
        )
    }

    private static func createExpensesToShow(filter: ExpenseType?, expenses: [Expense]) -> [Expense] {

        var expensesToShow = expenses.filter { expense in
            !expense.isInitialRecord &&
            expense.cost != nil &&
            expense.cost! > 0
        }

        if (filter == nil) {
            return expensesToShow
        }

        expensesToShow = expensesToShow.filter { x in
            x.expenseType == filter!
        }

        return expensesToShow
    }

    func recreateExpensesToShow(_ filter: ExpenseType?) -> Void {

        self.expensesToShow = ExpensesChartViewModel.createExpensesToShow(
            filter: filter,
            expenses: expenses)
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

    func localizedExpenseType(_ type: ExpenseType) -> String {
        switch type {
        case .charging:
            return L("Filter.Charges")
        case .repair:
            return L("Filter.Repair")
        case .maintenance:
            return L("Filter.Maintenance")
        case .carwash:
            return L("Filter.Carwash")
        case .other:
            return L("Other")
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
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            
            let monthExpenses = expensesToShow.filter { expense in
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
