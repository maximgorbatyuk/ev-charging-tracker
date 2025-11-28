//
//  MockDelayedNotificationsRepository.swift
//  EVChargingTrackerTests
//
//  Mock implementation of DelayedNotificationsRepositoryProtocol for testing
//

import Foundation
@testable import EVChargingTracker

class MockDelayedNotificationsRepository: DelayedNotificationsRepositoryProtocol {
    var notifications: [DelayedNotification] = []
    var insertedNotifications: [DelayedNotification] = []
    var deletedNotificationIds: [Int64] = []
    var nextInsertId: Int64 = 1
    
    func getRecordByMaintenanceId(_ maintenanceRecordId: Int64) -> DelayedNotification? {
        return notifications.first { $0.maintenanceRecord == maintenanceRecordId }
    }
    
    func insertRecord(_ record: DelayedNotification) -> Int64? {
        insertedNotifications.append(record)
        let id = nextInsertId
        nextInsertId += 1
        return id
    }
    
    func deleteRecord(id recordId: Int64) -> Bool {
        deletedNotificationIds.append(recordId)
        return true
    }
}
