//
//  DatabaseManagerFake.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 28.11.2025.
//

import Foundation

class DatabaseManagerFake : DatabaseManagerProtocol {
    
    let plannedMaintenanceRepository: PlannedMaintenanceRepository
    let delayedNotificationsRepository: DelayedNotificationsRepository
    let carRepository: CarRepository

    func getPlannedMaintenanceRepository() -> PlannedMaintenanceRepository {
        return plannedMaintenanceRepository
    }

    func getDelayedNotificationsRepository() -> DelayedNotificationsRepository {
        return delayedNotificationsRepository
    }

    func getCarRepository() -> CarRepository {
        return carRepository
    }
}
