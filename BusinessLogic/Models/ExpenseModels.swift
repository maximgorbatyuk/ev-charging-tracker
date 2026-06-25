//
//  ExpenseModels.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.10.2025.
//

import Foundation

enum ExpenseType: String, CaseIterable, Codable {
    case charging = "charging"
    case fuel = "fuel"
    case maintenance = "maintenance"
    case repair = "repair"
    case carwash = "carwash"
    case other = "other"

    var localizedName: String {
        switch self {
        case .charging: return L("Filter.Charges")
        case .fuel: return L("Filter.Fuel")
        case .maintenance: return L("Filter.Maintenance")
        case .repair: return L("Filter.Repair")
        case .carwash: return L("Filter.Carwash")
        case .other: return L("Filter.Other")
        }
    }
}

/// Gasoline octane grades available for a Hybrid car's fuel fill-up, displayed
/// with the RON rating standard (e.g. "95 RON"). Stored as the bare number.
enum FuelType: String, Codable, CaseIterable {
    case octane92 = "92"
    case octane95 = "95"
    case octane98 = "98"
    case octane100 = "100"

    var localizedName: String {
        return String(format: L("Fuel.OctaneFormat"), rawValue)
    }
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

enum ExpensesFilter: String, CaseIterable {
  case all
  case charging
  case fuel
  case maintenance
  case repair
  case carwash
  case other

  var displayName: String {
    switch self {
    case .all:
      return L("expense.filter.all")
    case .charging:
      return L("expense.filter.charging")
    case .fuel:
      return L("expense.filter.fuel")
    case .maintenance:
      return L("expense.filter.maintenance")
    case .repair:
      return L("expense.filter.repair")
    case .carwash:
      return L("expense.filter.carwash")
    case .other:
      return L("expense.filter.other")
    }
  }

  var expenseTypes: [ExpenseType] {
    switch self {
    case .all:
      return []
    case .charging:
      return [.charging]
    case .fuel:
      return [.fuel]
    case .maintenance:
      return [.maintenance]
    case .repair:
      return [.repair]
    case .carwash:
      return [.carwash]
    case .other:
      return [.other]
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
    /// Set only for `.fuel` expenses on a Hybrid car. Price-per-unit is never
    /// stored — it is derived from `cost / fuelVolume` via getFuelPricePerUnit().
    var fuelType: FuelType?
    var fuelVolume: Double?

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
        carId: Int64? = nil,
        fuelType: FuelType? = nil,
        fuelVolume: Double? = nil) {
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
        self.fuelType = fuelType
        self.fuelVolume = fuelVolume
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
        carId: Int64? = nil,
        fuelType: FuelType? = nil,
        fuelVolume: Double? = nil) {
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
            carId: carId,
            fuelType: fuelType,
            fuelVolume: fuelVolume
        )
    }

    func setCarId(_ carId: Int64?) throws {
        if self.carId != nil {
            throw RuntimeError("Car ID is already set and cannot be changed.")
        }

        try self.setCarIdWithNoValidation(carId)
    }

    func setCarIdWithNoValidation(_ carId: Int64?) throws {
        if carId == nil {
            throw RuntimeError("Provided Car ID is nil. Cannot set nil Car ID.")
        }

        if self.carId == carId {
            return
        }

        self.carId = carId
    }

    func getPricePerKWh() -> Double? {
        if self.cost == nil ||
            self.energyCharged == 0 ||
            self.expenseType != .charging {
            return nil
        }

        return self.cost! / self.energyCharged
    }

    /// Derived fuel price-per-unit (per litre/gallon). Mirrors getPricePerKWh():
    /// no price is stored, so it is always computed from cost and volume. The
    /// single source of truth for the displayed/exported price-per-unit.
    func getFuelPricePerUnit() -> Double? {
        guard self.expenseType == .fuel,
              let cost = self.cost,
              let volume = self.fuelVolume,
              volume > 0
        else {
            return nil
        }

        return cost / volume
    }

}
