//
//  DelayedNotification.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.11.2025.
//

import Foundation

class DelayedNotification: Identifiable {
    var id: Int64?
    var when: Date
    var notificationId: String
    var maintenanceRecord: Int64?
    var carId: Int64
    var createdAt: Date
    
    init(
        id: Int64? = nil,
        when: Date,
        notificationId: String,
        maintenanceRecord: Int64?,
        carId: Int64,
        createdAt: Date?) {

        self.id = id
        self.when = when
        self.notificationId = notificationId
        self.maintenanceRecord = maintenanceRecord
        self.carId = carId
        self.createdAt = createdAt ?? Date()
    }

    // Convenience initializer to match existing call sites that construct without the `id:` label.
    convenience init(
        when: Date,
        notificationId: String,
        maintenanceRecord: Int64?,
        carId: Int64) {
        self.init(
            id: nil,
            when: when,
            notificationId: notificationId,
            maintenanceRecord: maintenanceRecord,
            carId: carId,
            createdAt: nil
        )
    }
}
