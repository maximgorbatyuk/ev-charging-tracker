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
    case carwash = "carwash"
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
    case other = "Other"
}

class Expense: Identifiable {
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
    var carId: Int64?

    init(
        id: Int64? = nil,
        date: Date,
        energyCharged: Double,
        chargerType: ChargerType,
        odometer: Int,
        cost: Double? = nil,
        notes: String,
        isInitialRecord: Bool,
        expenseType: ExpenseType,
        currency: Currency,
        carId: Int64? = nil) {
        self.id = id
        self.date = date
        self.energyCharged = energyCharged
        self.chargerType = chargerType
        self.odometer = odometer
        self.cost = cost
        self.notes = notes
        self.isInitialRecord = isInitialRecord
        self.expenseType = expenseType
        self.currency = currency
        self.carId = carId
    }

    // Convenience initializer to match existing call sites that construct
    // Expense(date: ..., energyCharged: ..., ... ) without the `id:` label.
    convenience init(
        date: Date,
        energyCharged: Double,
        chargerType: ChargerType,
        odometer: Int,
        cost: Double? = nil,
        notes: String,
        isInitialRecord: Bool,
        expenseType: ExpenseType,
        currency: Currency,
        carId: Int64? = nil) {
        self.init(
            id: nil,
            date: date,
            energyCharged: energyCharged,
            chargerType: chargerType,
            odometer: odometer,
            cost: cost,
            notes: notes,
            isInitialRecord: isInitialRecord,
            expenseType: expenseType,
            currency: currency,
            carId: carId
        )
    }

    func setCarId(_ carId: Int64?) -> Void {
        if (self.carId != nil) {
            print("Car ID is already set and cannot be changed.")
            return
        }
        
        if (carId == nil) {
            print("Provided Car ID is nil. Cannot set nil Car ID.")
            return
        }

        self.carId = carId
    }
}
