//
//  CarRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.10.2025.
//

@_exported import SQLite
import Foundation

class CarRepository {
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

    private let userSettingsRepository: UserSettingsRepository

    private var db: Connection
    
    init(
        db: Connection,
        tableName: String,
        expensesTableName: String,
        userSettingsTableName: String) {

        self.db = db
        self.table = Table(tableName)
        self.expensesTable = Table(expensesTableName)
        self.userSettingsRepository = UserSettingsRepository(db: db, tableName: userSettingsTableName)
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
            print("Table deleted successfully")
        } catch {
            print("Unable to delete table: \(error)")
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
                initialMileageColumn <- car.currentMileage,
                milleageSyncedAtColumn <- car.milleageSyncedAt,
                createdAtColumn <- currentDate
            )

            let rowId = try db.run(insert)
            print("Inserted car with id: \(rowId)")
            return rowId
        } catch {
            print("Insert failed: \(error)")
            return nil
        }
    }

    func updateMilleage(_ car: Car) -> Bool {
        guard let carId = car.id else {
            print("Update failed: Car id is nil")
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
            print("Update failed: \(error)")
            return false
        }
    }

    func delete(id: Int64) -> Bool {
        
        let carExpenses = expensesTable.filter(Expression<Int64>("car_id") == id)
        do {
            let deletionResult = try db.run(carExpenses.delete())
            if (deletionResult > 0) {
                print("Deleted \(deletionResult) related expenses for car id: \(id)")
            }
        } catch {
            print("Failed to delete related expenses: \(error)")
            return false
        }

        let carCommand = table.filter(idColumn == id)

        do {
            let deleted = try db.run(carCommand.delete())
            return deleted > 0
        } catch {
            print("Delete failed: \(error)")
            return false
        }
    }

    func getCarsCount() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            print("Failed to get cars count: \(error)")
            return 0
        }
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
                    createdAt: row[createdAtColumn]
                )
                cars.append(carItems)
            }
        }
        catch {
            print("Failed to fetch cars: \(error)")
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
                    createdAt: row[createdAtColumn]
                )
            }
        } catch {
            print("Failed to fetch selected car for expenses: \(error)")
        }

        return nil
    }

}
