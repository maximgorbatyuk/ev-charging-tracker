//
//  ExportModels.swift
//  EVChargingTracker
//
//  Models for exporting and importing app data
//

import Foundation

// MARK: - Export Root Structure

struct ExportData: Codable {
    let metadata: ExportMetadata
    let cars: [ExportCar]
    let expenses: [ExportExpense]
    let plannedMaintenance: [ExportPlannedMaintenance]
    let delayedNotifications: [ExportDelayedNotification]
    let userSettings: ExportUserSettings
}

// MARK: - Metadata

struct ExportMetadata: Codable {
    let createdAt: Date
    let appVersion: String
    let deviceName: String
    let databaseSchemaVersion: Int

    init(createdAt: Date = Date(),
         appVersion: String,
         deviceName: String,
         databaseSchemaVersion: Int) {
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.deviceName = deviceName
        self.databaseSchemaVersion = databaseSchemaVersion
    }
}

// MARK: - Export Car

struct ExportCar: Codable {
    let id: Int64?
    let name: String
    let selectedForTracking: Bool
    let batteryCapacity: Double?
    let expenseCurrency: String
    let currentMileage: Int
    let initialMileage: Int
    let milleageSyncedAt: Date
    let createdAt: Date
    let frontWheelSize: String?
    let rearWheelSize: String?

    init(from car: Car) {
        self.id = car.id
        self.name = car.name
        self.selectedForTracking = car.selectedForTracking
        self.batteryCapacity = car.batteryCapacity
        self.expenseCurrency = car.expenseCurrency.rawValue
        self.currentMileage = car.currentMileage
        self.initialMileage = car.initialMileage
        self.milleageSyncedAt = car.milleageSyncedAt
        self.createdAt = car.createdAt
        self.frontWheelSize = car.frontWheelSize
        self.rearWheelSize = car.rearWheelSize
    }

    func toCar() -> Car {
        let car = Car(
            name: name,
            selectedForTracking: selectedForTracking,
            batteryCapacity: batteryCapacity,
            expenseCurrency: Currency(rawValue: expenseCurrency) ?? .usd,
            currentMileage: currentMileage,
            initialMileage: initialMileage,
            milleageSyncedAt: milleageSyncedAt,
            createdAt: createdAt,
            frontWheelSize: frontWheelSize,
            rearWheelSize: rearWheelSize
        )
        car.id = id
        return car
    }
}

// MARK: - Export Expense

struct ExportExpense: Codable {
    let id: Int64?
    let date: Date
    let energyCharged: Double
    let chargerType: String
    let odometer: Int
    let cost: String?
    let notes: String
    let isInitialRecord: Bool
    let expenseType: String
    let currency: String
    let carId: Int64?

    init(from expense: Expense) {
        self.id = expense.id
        self.date = expense.date
        self.energyCharged = expense.energyCharged
        self.chargerType = expense.chargerType.rawValue
        self.odometer = expense.odometer
        self.cost = expense.cost.map { String($0) }
        self.notes = expense.notes
        self.isInitialRecord = expense.isInitialRecord
        self.expenseType = expense.expenseType.rawValue
        self.currency = expense.currency.rawValue
        self.carId = expense.carId
    }

    func toExpense() throws -> Expense {
        let expense = Expense(
            date: date,
            energyCharged: energyCharged,
            chargerType: ChargerType(rawValue: chargerType) ?? .other,
            odometer: odometer,
            cost: cost.flatMap { Double($0) },
            notes: notes,
            isInitialRecord: isInitialRecord,
            expenseType: ExpenseType(rawValue: expenseType) ?? .other,
            currency: Currency(rawValue: currency) ?? .usd
        )

        expense.id = id

        // Use the special setter for carId
        if let carId = carId {
            try expense.setCarIdWithNoValidation(carId)
        }
        return expense
    }
}

// MARK: - Export PlannedMaintenance

struct ExportPlannedMaintenance: Codable {
    let id: Int64?
    let odometer: Int?
    let name: String
    let notes: String
    let when: Date?
    let carId: Int64
    let createdAt: Date

    init(from maintenance: PlannedMaintenance) {
        self.id = maintenance.id
        self.odometer = maintenance.odometer
        self.name = maintenance.name
        self.notes = maintenance.notes
        self.when = maintenance.when
        self.carId = maintenance.carId
        self.createdAt = maintenance.createdAt
    }

    func toPlannedMaintenance() -> PlannedMaintenance {
        let maintenance = PlannedMaintenance(
            when: when,
            odometer: odometer,
            name: name,
            notes: notes,
            carId: carId,
            createdAt: createdAt
        )
        maintenance.id = id
        return maintenance
    }
}

// MARK: - Export DelayedNotification

struct ExportDelayedNotification: Codable {
    let id: Int64?
    let when: Date
    let notificationId: String
    let maintenanceRecord: Int64?
    let carId: Int64
    let createdAt: Date

    init(from notification: DelayedNotification) {
        self.id = notification.id
        self.when = notification.when
        self.notificationId = notification.notificationId
        self.maintenanceRecord = notification.maintenanceRecord
        self.carId = notification.carId
        self.createdAt = notification.createdAt
    }

    func toDelayedNotification() -> DelayedNotification {
        let notification = DelayedNotification(
            when: when,
            notificationId: notificationId,
            maintenanceRecord: maintenanceRecord,
            carId: carId,
            createdAt: createdAt
        )
        notification.id = id
        return notification
    }
}

// MARK: - Export UserSettings

struct ExportUserSettings: Codable {
    let preferredCurrency: String
    let preferredLanguage: String

    init(currency: Currency, language: AppLanguage) {
        self.preferredCurrency = currency.rawValue
        self.preferredLanguage = language.rawValue
    }
}

// MARK: - Validation Errors

enum ExportValidationError: LocalizedError {
    case invalidJSON
    case missingMetadata
    case missingRequiredFields
    case incompatibleSchemaVersion(current: Int, file: Int)
    case newerSchemaVersion(current: Int, file: Int)
    case invalidDate
    case invalidNumericValue(field: String)
    case invalidCurrency(code: String)
    case invalidEnumValue(type: String, value: String)
    case invalidReference(type: String, id: Int64)
    case corruptedData

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return String(localized: "export.error.invalid_json")
        case .missingMetadata:
            return String(localized: "export.error.missing_metadata")
        case .missingRequiredFields:
            return String(localized: "export.error.missing_fields")
        case .incompatibleSchemaVersion(let current, let file):
            return String(localized: "export.error.incompatible_schema \(current) \(file)")
        case .newerSchemaVersion(let current, let file):
            return String(localized: "export.error.newer_schema \(current) \(file)")
        case .invalidDate:
            return String(localized: "export.error.invalid_date")
        case .invalidNumericValue(let field):
            return String(localized: "export.error.invalid_numeric \(field)")
        case .invalidCurrency(let code):
            return String(localized: "export.error.invalid_currency \(code)")
        case .invalidEnumValue(let type, let value):
            return String(localized: "export.error.invalid_enum \(type) \(value)")
        case .invalidReference(let type, let id):
            return String(localized: "export.error.invalid_reference \(type) \(id)")
        case .corruptedData:
            return String(localized: "export.error.corrupted")
        }
    }
}
