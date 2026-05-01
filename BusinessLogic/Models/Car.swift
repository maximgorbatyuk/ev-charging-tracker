//
//  Car.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.10.2025.
//

import Foundation

class Car: Codable, Identifiable {
    var id: Int64?
    var name: String
    var selectedForTracking: Bool
    var batteryCapacity: Double? // in kWh
    var expenseCurrency: Currency
    var currentMileage: Int // raw integer; unit depends on `measurementSystem`
    var initialMileage: Int // raw integer; unit depends on `measurementSystem`
    var milleageSyncedAt: Date
    var createdAt: Date
    var frontWheelSize: String?
    var rearWheelSize: String?
    /// Per-car distance/weight unit. Switching systems does NOT change
    /// stored mileage values (see MeasurementSystem.swift).
    var measurementSystem: MeasurementSystem

    init(
        id: Int64? = nil,
        name: String,
        selectedForTracking: Bool,
        batteryCapacity: Double?,
        expenseCurrency: Currency,
        currentMileage: Int,
        initialMileage: Int,
        milleageSyncedAt: Date,
        createdAt: Date,
        frontWheelSize: String? = nil,
        rearWheelSize: String? = nil,
        measurementSystem: MeasurementSystem = .metric) {

        self.id = id
        self.name = name
        self.selectedForTracking = selectedForTracking
        self.batteryCapacity = batteryCapacity
        self.expenseCurrency = expenseCurrency
        self.currentMileage = currentMileage
        self.initialMileage = initialMileage

        self.milleageSyncedAt = milleageSyncedAt
        self.createdAt = createdAt
        self.frontWheelSize = frontWheelSize
        self.rearWheelSize = rearWheelSize
        self.measurementSystem = measurementSystem
    }

    func updateMileage(newMileage: Int) {
        if self.currentMileage >= newMileage {
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
        currentMileage: Int,
        expenseCurrency: Currency,
        selectedForTracking: Bool,
        frontWheelSize: String?,
        rearWheelSize: String?,
        measurementSystem: MeasurementSystem) {
        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.name = name
        }

        if batteryCapacity != nil && batteryCapacity! > 0 {
            self.batteryCapacity = batteryCapacity
        }

        if currentMileage > 0 && currentMileage >= self.initialMileage {
            self.currentMileage = currentMileage
            self.milleageSyncedAt = Date()
        }

        if intialMileage <= self.currentMileage {
            self.initialMileage = intialMileage
        }

        self.expenseCurrency = expenseCurrency
        self.selectedForTracking = selectedForTracking
        self.frontWheelSize = frontWheelSize
        self.rearWheelSize = rearWheelSize
        self.measurementSystem = measurementSystem
    }
}
