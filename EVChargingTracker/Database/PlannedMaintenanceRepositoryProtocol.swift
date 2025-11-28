//
//  PlannedMaintenanceRepositoryProtocol.swift
//  EVChargingTracker
//
//  Created for unit testing support
//

import Foundation

protocol PlannedMaintenanceRepositoryProtocol {
    func getAllRecords(carId: Int64) -> [PlannedMaintenance]
    func insertRecord(_ record: PlannedMaintenance) -> Int64?
    func deleteRecord(id recordId: Int64) -> Bool
}

extension PlannedMaintenanceRepository: PlannedMaintenanceRepositoryProtocol {}
