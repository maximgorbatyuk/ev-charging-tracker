//
//  CarRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.10.2025.
//

@_exported import SQLite
import Foundation
import os

protocol CarRepositoryProtocol {
    func getSelectedForExpensesCar() -> Car?
    func getAllCars() -> [Car]
    func insert(_ car: Car) -> Int64?
    func updateMilleage(_ car: Car) -> Bool
}

class CarRepository : CarRepositoryProtocol {
    private let table: Table
    private let expensesTable: Table

    private let idColumn = Expression<Int64>("id")
    private let nameColumn = Expression<String>("name")
    private let selectedForTrackingColumn = Expression<Bool>("selected_for_tracking")
    private let batteryCapacityColumn = Expression<Double?>("battery_capacity")
    private let expenseCurrencyColumn = Expression<String>("expense_currency")
    private let currentMileageColumn = Expression<Int>("current_mileage")
    private let initialMileageColumn = Expression<Int>("initial_mileage")
    private let milleageSyncedAtColumn = Expression<Date>("milleage_synced_at")
    private let createdAtColumn = Expression<Date>("created_at")
    private let frontWheelSizeColumn = Expression<String?>("front_wheel_size")
    private let rearWheelSizeColumn = Expression<String?>("rear_wheel_size")

    private let userSettingsRepository: UserSettingsRepository
    private var db: Connection
    private let logger: Logger
    
    init(
        db: Connection,
        tableName: String,
        expensesTableName: String,
        userSettingsTableName: String,
        logger: Logger? = nil) {

        self.db = db
        self.table = Table(tableName)
        self.expensesTable = Table(expensesTableName)
        self.userSettingsRepository = UserSettingsRepository(db: db, tableName: userSettingsTableName)
        self.logger = logger ?? Logger(subsystem: "CarRepository", category: "Database")
    }

    func getCreateTableCommand() -> String {
        return table.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(nameColumn)
            t.column(selectedForTrackingColumn)
            t.column(batteryCapacityColumn)
            t.column(expenseCurrencyColumn)
            t.column(currentMileageColumn)
            t.column(initialMileageColumn)
            t.column(milleageSyncedAtColumn)
            t.column(createdAtColumn)
            t.column(frontWheelSizeColumn)
            t.column(rearWheelSizeColumn)
        }
    }

    func deleteTable() {
        do {
            let allCars = try db.prepare(table)

            for car in allCars {
                let carId = car[idColumn]
                let relatedExpenses = expensesTable.filter(Expression<Int64>("car_id") == carId)
                try db.run(relatedExpenses.delete())
            }

            try db.run(table.drop(ifExists: true))
            logger.info("Table deleted successfully")
        } catch {
            logger.error("Unable to delete table: \(error)")
        }
    }

    func truncateTable() -> Void {
        do {
            try db.run(table.delete())
            logger.info("Table truncated successfully")
        } catch {
            logger.error("Unable to truncate table: \(error)")
        }
    }

    func insert(_ car: Car) -> Int64? {

        let currentDate = Date()
        do {
            let insert = table.insert(
                nameColumn <- car.name,
                selectedForTrackingColumn <- car.selectedForTracking,
                batteryCapacityColumn <- car.batteryCapacity,
                expenseCurrencyColumn <- car.expenseCurrency.rawValue,
                currentMileageColumn <- car.currentMileage,
                initialMileageColumn <- car.initialMileage,
                milleageSyncedAtColumn <- car.milleageSyncedAt,
                createdAtColumn <- currentDate,
                frontWheelSizeColumn <- car.frontWheelSize,
                rearWheelSizeColumn <- car.rearWheelSize
            )

            let rowId = try db.run(insert)
            logger.info("Inserted car with id: \(rowId)")
            return rowId
        } catch {
            logger.error("Insert failed: \(error)")
            return nil
        }
    }

    func updateMilleage(_ car: Car) -> Bool {
        guard let carId = car.id else {
            logger.info("Update failed: Car id is nil")
            return false
        }

        let carToUpdate = table.filter(idColumn == carId)
        do {
            let update = carToUpdate.update(
                currentMileageColumn <- car.currentMileage,
                milleageSyncedAtColumn <- car.milleageSyncedAt
            )
            let updated = try db.run(update)
            return updated > 0
        } catch {
            logger.error("Update failed: \(error)")
            return false
        }
    }

    func getCarById(_ id: Int64) -> Car? {
        do {
            let query = table.filter(idColumn == id).limit(1)
            if let row = try db.pluck(query) {

                let currency = Currency(rawValue: row[expenseCurrencyColumn]) ?? userSettingsRepository.fetchCurrency()

                return Car(
                    id: row[idColumn],
                    name: row[nameColumn],
                    selectedForTracking: row[selectedForTrackingColumn],
                    batteryCapacity: row[batteryCapacityColumn],
                    expenseCurrency: currency,
                    currentMileage: row[currentMileageColumn],
                    initialMileage: row[initialMileageColumn],
                    milleageSyncedAt: row[milleageSyncedAtColumn],
                    createdAt: row[createdAtColumn],
                    frontWheelSize: row[frontWheelSizeColumn],
                    rearWheelSize: row[rearWheelSizeColumn]
                )
            }
        } catch {
            logger.error("Failed to fetch car by id \(id): \(error)")
        }

        return nil
    }

    func updateCar(car: Car) -> Bool {
        guard let carId = car.id else {
            logger.info("Update failed: Car id is nil")
            return false
        }
        let carToUpdate = table.filter(idColumn == carId)
        do {
            let update = carToUpdate.update(
                nameColumn <- car.name,
                batteryCapacityColumn <- car.batteryCapacity,
                initialMileageColumn <- car.initialMileage,
                currentMileageColumn <- car.currentMileage,
                expenseCurrencyColumn <- car.expenseCurrency.rawValue,
                milleageSyncedAtColumn <- car.milleageSyncedAt,
                selectedForTrackingColumn <- car.selectedForTracking,
                frontWheelSizeColumn <- car.frontWheelSize,
                rearWheelSizeColumn <- car.rearWheelSize
            )
            let updated = try db.run(update)
            return updated > 0
        } catch {
            logger.error("Update failed: \(error)")
            return false
        }
    }

    func getCarsCountExcludingId(_ carIdToExclude: Int64) -> Int {
        let carsToCount = table.filter(idColumn != carIdToExclude)
        do {
            return try db.scalar(carsToCount.count)
        } catch {
            logger.error("Failed to get cars count excluding id \(carIdToExclude): \(error)")
            return 0
        }
    }

    func markAllCarsAsNoTracking(carIdToExclude: Int64) -> Bool {
        let carsToUpdate = table.filter(idColumn != carIdToExclude)
        do {
            let update = carsToUpdate.update(
                selectedForTrackingColumn <- false
            )
            let updated = try db.run(update)
            return updated > 0
        } catch {
            logger.error("Update failed: \(error)")
            return false
        }
    }

    func markCarAsSelectedForTracking(_ id: Int64) -> Bool {
        let carToUpdate = table.filter(idColumn == id)
        do {
            let update = carToUpdate.update(
                selectedForTrackingColumn <- true
            )
            let updated = try db.run(update)
            return updated > 0
        } catch {
            logger.error("Update failed: \(error)")
            return false
        }
    }

    func delete(id: Int64) -> Bool {
        
        let carExpenses = expensesTable.filter(Expression<Int64>("car_id") == id)
        do {
            let deletionResult = try db.run(carExpenses.delete())
            if (deletionResult > 0) {
                logger.info("Deleted \(deletionResult) related expenses for car id: \(id)")
            }
        } catch {
            logger.error("Failed to delete related expenses: \(error)")
            return false
        }

        let carCommand = table.filter(idColumn == id)

        do {
            let deleted = try db.run(carCommand.delete())
            return deleted > 0
        } catch {
            logger.error("Delete failed: \(error)")
            return false
        }
    }

    func getCarsCount() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to get cars count: \(error)")
            return 0
        }
    }

    func getLatestAddedCar() -> Car? {
        let query = table.order(createdAtColumn.desc).limit(1)
        do {
            if let row = try db.pluck(query) {
                let currency = Currency(rawValue: row[expenseCurrencyColumn]) ?? userSettingsRepository.fetchCurrency()

                let rowId = row[idColumn]
                return Car(
                    id: rowId,
                    name: row[nameColumn],
                    selectedForTracking: row[selectedForTrackingColumn],
                    batteryCapacity: row[batteryCapacityColumn],
                    expenseCurrency: currency,
                    currentMileage: row[currentMileageColumn],
                    initialMileage: row[initialMileageColumn],
                    milleageSyncedAt: row[milleageSyncedAtColumn],
                    createdAt: row[createdAtColumn],
                    frontWheelSize: row[frontWheelSizeColumn],
                    rearWheelSize: row[rearWheelSizeColumn]
                )
            } else {
                return nil
            }
        } catch {
            logger.error("Failed to fetch latest added car: \(error)")
        }

        return nil
    }

    func getAllCars() -> [Car] {
        var cars: [Car] = []
        do {
            let allCars = try db.prepare(table)
            for row in allCars {

                let currency = Currency(rawValue: row[expenseCurrencyColumn]) ?? userSettingsRepository.fetchCurrency()

                let rowId = row[idColumn]
                let carItems = Car(
                    id: rowId,
                    name: row[nameColumn],
                    selectedForTracking: row[selectedForTrackingColumn],
                    batteryCapacity: row[batteryCapacityColumn],
                    expenseCurrency: currency,
                    currentMileage: row[currentMileageColumn],
                    initialMileage: row[initialMileageColumn],
                    milleageSyncedAt: row[milleageSyncedAtColumn],
                    createdAt: row[createdAtColumn],
                    frontWheelSize: row[frontWheelSizeColumn],
                    rearWheelSize: row[rearWheelSizeColumn]
                )
                cars.append(carItems)
            }
        }
        catch {
            logger.error("Failed to fetch cars: \(error)")
        }

        return cars
    }

    func getSelectedForExpensesCar() -> Car? {
        do {
            let query = table.filter(selectedForTrackingColumn == true).limit(1)
            if let row = try db.pluck(query) {

                var expenseCurrency = Currency(rawValue: row[expenseCurrencyColumn])
                if (expenseCurrency == nil) {
                    expenseCurrency = userSettingsRepository.fetchCurrency()
                }

                return Car(
                    id: row[idColumn],
                    name: row[nameColumn],
                    selectedForTracking: row[selectedForTrackingColumn],
                    batteryCapacity: row[batteryCapacityColumn],
                    expenseCurrency: expenseCurrency ?? .kzt,
                    currentMileage: row[currentMileageColumn],
                    initialMileage: row[initialMileageColumn],
                    milleageSyncedAt: row[milleageSyncedAtColumn],
                    createdAt: row[createdAtColumn],
                    frontWheelSize: row[frontWheelSizeColumn],
                    rearWheelSize: row[rearWheelSizeColumn]
                )
            }
        } catch {
            logger.error("Failed to fetch selected car for expenses: \(error)")
        }

        return nil
    }

}
