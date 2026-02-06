//
//  MockPlannedMaintenanceRepository.swift
//  EVChargingTrackerTests
//
//  Mock implementation of PlannedMaintenanceRepositoryProtocol for testing
//

import Foundation

class MockPlannedMaintenanceRepository: PlannedMaintenanceRepositoryProtocol {
    var records: [PlannedMaintenance] = []
    var insertedRecords: [PlannedMaintenance] = []
    var deletedRecordIds: [Int64] = []
    var nextInsertId: Int64 = 1

    func getAllRecords(carId: Int64) -> [PlannedMaintenance] {
        return records.filter { $0.carId == carId }
    }

    func getFilteredRecordsPaginated(
        carId: Int64,
        filter: PlannedMaintenanceFilter,
        currentMileage: Int,
        currentDate: Date,
        page: Int,
        pageSize: Int
    ) -> [PlannedMaintenance] {
        let filtered = records.filter { $0.carId == carId }
        let offset = (page - 1) * pageSize
        let end = min(offset + pageSize, filtered.count)

        guard offset < filtered.count else {
            return []
        }

        return Array(filtered[offset..<end])
    }

    func getFilteredRecordsCount(
        carId: Int64,
        filter: PlannedMaintenanceFilter,
        currentMileage: Int,
        currentDate: Date
    ) -> Int {
        return records.filter { $0.carId == carId }.count
    }

    func insertRecord(_ record: PlannedMaintenance) -> Int64? {
        insertedRecords.append(record)
        let id = nextInsertId
        nextInsertId += 1
        return id
    }

    func updateRecord(_ record: PlannedMaintenance) -> Bool {
        return true
    }

    func deleteRecord(id recordId: Int64) -> Bool {
        deletedRecordIds.append(recordId)
        return true
    }
}
