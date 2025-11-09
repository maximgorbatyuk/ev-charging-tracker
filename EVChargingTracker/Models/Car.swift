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

        self.id = id
        self.name = name
        self.selectedForTracking = selectedForTracking
        self.batteryCapacity = batteryCapacity
        self.expenseCurrency = expenseCurrency
        self.currentMileage = currentMileage
        self.initialMileage = initialMileage

        self.milleageSyncedAt = milleageSyncedAt
        self.createdAt = createdAt
    }
    
    func updateMileage(newMileage: Int) {
        if (self.currentMileage >= newMileage) {
            return
        }

        self.currentMileage = newMileage
        self.milleageSyncedAt = Date()
    }

    func getTotalMileage() -> Int {
        return self.currentMileage - self.initialMileage
    }
    
    func updateValues(
        name: String,
        batteryCapacity: Double?,
        intialMileage: Int,
        currentMileage: Int) -> Void {
        if (!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            self.name = name
        }

        if (batteryCapacity != nil && batteryCapacity! > 0) {
            self.batteryCapacity = batteryCapacity
        }

        if (currentMileage > 0 && currentMileage >= self.currentMileage) {
            self.currentMileage = currentMileage
            self.milleageSyncedAt = Date()
        }

        if (intialMileage <= self.currentMileage) {
            self.initialMileage = intialMileage
        }
            
    }
}
