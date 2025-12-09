//
//  ExpensesChartData.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 09.12.2025.
//

import Foundation

struct ExpensesChartData: Identifiable {
    var id = UUID()
    let expenses: [Expense]
    let currency: Currency
    let analytics: AnalyticsService
    let monthsCount: Int
}
