//
//  TestHelpers.swift
//  EVChargingTrackerTests
//
//  Helper functions for creating test data
//

import Foundation
@testable import EVChargingTracker

func createTestCar(
    id: Int64 = 1,
    name: String = "Test Car",
    currentMileage: Int = 50000
) -> Car {
    return Car(
        id: id,
        name: name,
        selectedForTracking: true,
        batteryCapacity: 75.0,
        expenseCurrency: .usd,
        currentMileage: currentMileage,
        initialMileage: 0,
        milleageSyncedAt: Date(),
        createdAt: Date()
    )
}

func createTestMaintenance(
    id: Int64 = 1,
    name: String = "Oil Change",
    notes: String = "Test notes",
    when: Date? = nil,
    odometer: Int? = nil,
    carId: Int64 = 1
) -> PlannedMaintenance {
    return PlannedMaintenance(
        id: id,
        when: when,
        odometer: odometer,
        name: name,
        notes: notes,
        carId: carId,
        createdAt: Date()
    )
}
