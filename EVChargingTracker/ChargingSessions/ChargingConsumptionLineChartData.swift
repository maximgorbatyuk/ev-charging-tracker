//
//  ChargingConsumptionLineChartData.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 09.12.2025.
//

import Foundation

struct ChargingConsumptionLineChartData: Identifiable {
    var id = UUID()
    let expenses: [Expense]
    let analytics: AnalyticsService
    let monthsCount: Int
}
