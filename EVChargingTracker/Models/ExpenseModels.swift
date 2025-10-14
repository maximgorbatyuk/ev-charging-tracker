//
//  ExpenseModels.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.10.2025.
//

import Foundation

enum ExpenseType: String, CaseIterable, Codable {
    case charging = "charging"
    case maintenance = "maintenance"
    case repair = "repair"
    case other = "other"
}

enum ChargerType: String, CaseIterable, Codable {
    case home7kW = "Home (7kW)"
    case home11kW = "Home (11kW)"
    case destination22kW = "Destination (22kW)"
    case superchargerV2 = "Supercharger V2 (150kW)"
    case superchargerV3 = "Supercharger V3 (250kW)"
    case superchargerV4 = "Supercharger V4 (350kW)"
    case publicFast50kW = "Public Fast (50kW)"
    case publicRapid100kW = "Public Rapid (100kW)"
}

struct Expense: Identifiable {
    var id: Int64?
    var date: Date
    var energyCharged: Double
    var chargerType: ChargerType
    var odometer: Int
    var cost: Double?
    var notes: String
    var isInitialRecord: Bool
    var expenseType: ExpenseType
    var currency: Currency
}
