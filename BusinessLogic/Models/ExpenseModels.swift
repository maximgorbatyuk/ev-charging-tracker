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

enum ExpensesSortingOption: String, CaseIterable, Codable {
    case creationDate = "creation_date"
    case odometer = "odometer"

    var localizedTitle: String {
        switch self {
        case .creationDate:
            return L("Sort.CreationDate")
        case .odometer:
            return L("Sort.Odometer")
        }
    }
}

enum ChargerType: String, CaseIterable, Codable {
    case home3kW = "Home (3kW)"
    case home7kW = "Home (7kW)"
    case home11kW = "Home (11kW)"
    case destination22kW = "Destination (22kW)"
    case publicFast50kW = "Public Fast (50kW)"
    case publicRapid100kW = "Public Rapid (100kW)"
    case superchargerV2 = "Supercharger V2 (150kW)"
    case superchargerV3 = "Supercharger V3 (250kW)"
    case superchargerV4 = "Supercharger V4 (350kW)"
    case other = "Other"
}

class Expense: Codable, Identifiable {
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

    func setCarId(_ carId: Int64?) throws -> Void {
        if (self.carId != nil) {
            throw RuntimeError("Car ID is already set and cannot be changed.")
        }

        try self.setCarIdWithNoValidation(carId)
    }

    func setCarIdWithNoValidation(_ carId: Int64?) throws -> Void {
        if (carId == nil) {
            throw RuntimeError("Provided Car ID is nil. Cannot set nil Car ID.")
        }

        if (self.carId == carId) {
            return
        }

        self.carId = carId
    }

    func getPricePerKWh() -> Double? {
        if (self.cost == nil ||
            self.energyCharged == 0 ||
            self.expenseType != .charging) {
            return nil
        }
   
        return self.cost! / self.energyCharged
    }
    

}
