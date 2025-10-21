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
    private let currentMileageColumn = Expression<Double>("current_mileage")
    private let milleageSyncedAtColumn = Expression<Date>("milleage_synced_at")
    private let createdAtColumn = Expression<Date>("created_at")

    private var db: Connection
    
    init(db: Connection, tableName: String, expensesTableName: String) {
        self.db = db
        self.table = Table(tableName)
        self.expensesTable = Table(expensesTableName)
    }

    func getCreateTableCommand() -> String {
        return table.create(ifNotExists: true) { t in
            t.column(idColumn, primaryKey: .autoincrement)
            t.column(nameColumn)
            t.column(selectedForTrackingColumn)
            t.column(batteryCapacityColumn)
            t.column(expenseCurrencyColumn)
            t.column(currentMileageColumn)
            t.column(milleageSyncedAtColumn)
            t.column(createdAtColumn)
        }
    }

    func deleteTable() {
        do {
            var allCars = try db.prepare(table)
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
    
    func delete(id: Int64) -> Bool {
        let car = table.filter(idColumn == id)
        do {
            var deleted = try db.run()
            
            let deleted = try db.run(car.delete())
            if (deleted > 0) {
                
            }

            return false
        } catch {
            print("Delete failed: \(error)")
            return false
        }
    }

}
