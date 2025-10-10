//
//  ChargingSession.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 10.10.2025.
//

import Foundation

struct ChargingSession: Identifiable {
    var id: Int64?
    var date: Date
    var energyCharged: Double
    var chargerType: ChargerType
    var odometer: Int
    var cost: Double?
    var notes: String
    var isInitalRecord: Bool
}
