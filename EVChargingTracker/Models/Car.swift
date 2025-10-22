//
//  Car.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.10.2025.
//

import Foundation

class Car {
    var id: Int64?
    var name: String
    var selectedForTracking: Bool
    var batteryCapacity: Double? // in kWh
    var expenseCurrency: Currency
    var currentMileage: Int // in km
    var initialMileage: Int // in km
    var milleageSyncedAt: Date
    var createdAt: Date

    init(
        id: Int64? = nil,
        name: String,
        selectedForTracking: Bool,
        batteryCapacity: Double?,
        expenseCurrency: Currency,
        currentMileage: Int,
        initialMileage: Int,
        milleageSyncedAt: Date,
        createdAt: Date) {

        self.id = nil
        self.name = name
        self.selectedForTracking = selectedForTracking
        self.batteryCapacity = batteryCapacity
        self.expenseCurrency = expenseCurrency
        self.currentMileage = currentMileage
        self.initialMileage = initialMileage

        self.milleageSyncedAt = milleageSyncedAt
        self.createdAt = createdAt
    }
}
