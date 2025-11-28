//
//  DelayedNotificationsRepositoryProtocol.swift
//  EVChargingTracker
//
//  Created for unit testing support
//

import Foundation

protocol DelayedNotificationsRepositoryProtocol {
    func getRecordByMaintenanceId(_ maintenanceRecordId: Int64) -> DelayedNotification?
    func insertRecord(_ record: DelayedNotification) -> Int64?
    func deleteRecord(id recordId: Int64) -> Bool
}

extension DelayedNotificationsRepository: DelayedNotificationsRepositoryProtocol {}
