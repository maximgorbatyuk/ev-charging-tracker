import SwiftUI
import Foundation

@MainActor
class ChargingConsumptionChartViewModel: ObservableObject {
    @Published var monthlyData: [MonthlyConsumption] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let expenses: [Expense]
    private let analytics: AnalyticsService
    private let monthsCount: Int

    init(data: ChargingConsumptionLineChartData) {
        self.expenses = data.expenses
        self.analytics = data.analytics
        self.monthsCount = data.monthsCount

        loadMonthlyConsumption()
    }

    // Calculate total energy consumption per month for the last N months
    func loadMonthlyConsumption() {
        isLoading = true
        errorMessage = nil

        let calendar = Calendar.current
        let today = Date()
        var monthlyTotals: [MonthlyConsumption] = []

        for monthOffset in (0..<self.monthsCount).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: today),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
                  let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
                continue
            }

            // Filter expenses for this month that are actual charging sessions
            let monthExpenses = self.expenses.filter { expense in
                let isCharging = expense.expenseType == .charging && !expense.isInitialRecord
                let isInMonth = expense.date >= startOfMonth && expense.date < nextMonthStart
                return isCharging && isInMonth
            }

            let totalEnergy = monthExpenses.reduce(0.0) { $0 + $1.energyCharged }

            monthlyTotals.append(
                MonthlyConsumption(
                    month: startOfMonth,
                    totalEnergy: totalEnergy
            ))
        }

        monthlyData = monthlyTotals
        isLoading = false
    }

    // Get the maximum value for chart scaling
    var maxConsumption: Double {
        monthlyData.map { $0.totalEnergy }.max() ?? 0
    }

    // Get the minimum value for chart scaling
    var minConsumption: Double {
        let min = monthlyData.map { $0.totalEnergy }.min() ?? 0
        return max(0, min - 2) // Add some padding, but not below 0
    }

    // Check if there's any data to display
    var hasData: Bool {
        monthlyData.contains { $0.totalEnergy > 0 }
    }

    // Average monthly energy across all months with data
    var overallAverage: Double {
        let validData = monthlyData.filter { $0.totalEnergy > 0 }
        guard !validData.isEmpty else { return 0 }
        let sum = validData.reduce(0) { $0 + $1.totalEnergy }
        return sum / Double(validData.count)
    }
}

struct MonthlyConsumption: Identifiable {
    let id = UUID()
    let month: Date
    let totalEnergy: Double

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: month)
    }
}
