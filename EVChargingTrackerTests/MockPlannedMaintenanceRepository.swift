//
//  MockPlannedMaintenanceRepository.swift
//  EVChargingTrackerTests
//
//  Mock implementation of PlannedMaintenanceRepositoryProtocol for testing
//

import Foundation
@testable import EVChargingTracker

class MockPlannedMaintenanceRepository: PlannedMaintenanceRepositoryProtocol {
    var records: [PlannedMaintenance] = []
    var insertedRecords: [PlannedMaintenance] = []
    var deletedRecordIds: [Int64] = []
    var nextInsertId: Int64 = 1
    
    func getAllRecords(carId: Int64) -> [PlannedMaintenance] {
        return records.filter { $0.carId == carId }
    }
    
    func insertRecord(_ record: PlannedMaintenance) -> Int64? {
        insertedRecords.append(record)
        let id = nextInsertId
        nextInsertId += 1
        return id
    }
    
    func deleteRecord(id recordId: Int64) -> Bool {
        deletedRecordIds.append(recordId)
        return true
    }
}
