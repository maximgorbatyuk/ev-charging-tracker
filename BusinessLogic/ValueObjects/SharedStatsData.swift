//
//  SharedStatsData.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.11.2025.
//

import Foundation

class SharedStatsData {
    let co2Saved: Double
    let avgConsumptionKWhPer100: Double
    let totalChargingSessionsCount: Int
    let oneKmPriceBasedOnlyOnCharging: Double
    let oneKmPriceIncludingAllExpenses: Double
    let totalChargingCost: Double
    let lastUpdated: Date
    
    init(
        co2Saved: Double,
        avgConsumptionKWhPer100: Double,
        totalChargingSessionsCount: Int,
        totalChargingCost: Double,
        oneKmPriceIncludingAllExpenses: Double,
        oneKmPriceBasedOnlyOnCharging: Double,
        lastUpdated: Date) {
        self.co2Saved = co2Saved
        self.avgConsumptionKWhPer100 = avgConsumptionKWhPer100
        self.totalChargingSessionsCount = totalChargingSessionsCount
        self.oneKmPriceBasedOnlyOnCharging = oneKmPriceBasedOnlyOnCharging
        self.oneKmPriceIncludingAllExpenses = oneKmPriceIncludingAllExpenses
        self.totalChargingCost = totalChargingCost
        self.lastUpdated = lastUpdated
    }
}
