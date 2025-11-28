//
//  CarRepositoryProtocol.swift
//  EVChargingTracker
//
//  Created for unit testing support
//

import Foundation

protocol CarRepositoryProtocol {
    func getSelectedForExpensesCar() -> Car?
}

extension CarRepository: CarRepositoryProtocol {}
