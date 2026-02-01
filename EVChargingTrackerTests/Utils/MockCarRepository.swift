//
//  MockCarRepository.swift
//  EVChargingTrackerTests
//
//  Mock implementation of CarRepositoryProtocol for testing
//

import Foundation

class MockCarRepository: CarRepositoryProtocol {
    var cars: [Car] = []
    var selectedCar: Car?
    var insertedCars: [Car] = []
    var updatedCars: [Car] = []
    var nextInsertId: Int64 = 1

    // Call tracking
    var getSelectedCarCallCount = 0
    var getAllCarsCallCount = 0
    var insertCallCount = 0
    var updateMilleageCallCount = 0

    // MARK: - CarRepositoryProtocol

    func getSelectedForExpensesCar() -> Car? {
        getSelectedCarCallCount += 1
        return selectedCar
    }

    func getAllCars() -> [Car] {
        getAllCarsCallCount += 1
        return cars
    }

    func insert(_ car: Car) -> Int64? {
        insertCallCount += 1
        insertedCars.append(car)
        let id = nextInsertId
        nextInsertId += 1
        return id
    }

    func updateMilleage(_ car: Car) -> Bool {
        updateMilleageCallCount += 1
        updatedCars.append(car)
        return true
    }
}
