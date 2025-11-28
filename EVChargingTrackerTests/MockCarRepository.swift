//
//  MockCarRepository.swift
//  EVChargingTrackerTests
//
//  Mock implementation of CarRepositoryProtocol for testing
//

import Foundation
@testable import EVChargingTracker

class MockCarRepository: CarRepositoryProtocol {
    var selectedCar: Car?
    var getSelectedCarCallCount = 0
    
    func getSelectedForExpensesCar() -> Car? {
        getSelectedCarCallCount += 1
        return selectedCar
    }
}
