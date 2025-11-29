//
//  PlannedMaintenance.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

import Foundation

class PlannedMaintenance: Identifiable {
    var id: Int64?
    var odometer: Int?
    var name: String
    var notes: String
    var when: Date?
    var carId: Int64
    var createdAt: Date
    
    init(
        id: Int64? = nil,
        when: Date?,
        odometer: Int?,
        name: String,
        notes: String,
        carId: Int64,
        createdAt: Date?) {

        self.id = id
        self.when = when
        self.odometer = odometer
        self.notes = notes
        self.name = name
        self.carId = carId
        self.createdAt = createdAt ?? Date()
    }

    // Convenience initializer to match existing call sites that construct without the `id:` label.
    convenience init(
        when: Date?,
        odometer: Int?,
        name: String,
        notes: String,
        carId: Int64) {
        self.init(
            id: nil,
            when: when,
            odometer: odometer,
            name: name,
            notes: notes,
            carId: carId,
            createdAt: nil
        )
    }
}
