//
//  ExpenseType.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

enum ExpenseType: String, CaseIterable, Codable {
    case charging = "charging"
    case maintenance = "maintenance"
    case repair = "repair"
    case other = "other"
}
