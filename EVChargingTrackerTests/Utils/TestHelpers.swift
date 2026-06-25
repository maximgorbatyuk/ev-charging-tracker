//
//  TestHelpers.swift
//  EVChargingTrackerTests
//
//  Helper functions for creating test data
//

import Foundation

func createTestCar(
    id: Int64 = 1,
    name: String = "Test Car",
    currentMileage: Int = 50000,
    carType: CarType = .electric
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
        createdAt: Date(),
        carType: carType
    )
}

func createTestFuelExpense(
    id: Int64 = 1,
    cost: Double? = 60.0,
    fuelType: FuelType? = .octane95,
    fuelVolume: Double? = 40.0,
    carId: Int64 = 1
) -> Expense {
    return Expense(
        id: id,
        date: Date(),
        energyCharged: 0,
        chargerType: .other,
        odometer: 50000,
        cost: cost,
        notes: "",
        isInitialRecord: false,
        expenseType: .fuel,
        currency: .usd,
        carId: carId,
        fuelType: fuelType,
        fuelVolume: fuelVolume
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
