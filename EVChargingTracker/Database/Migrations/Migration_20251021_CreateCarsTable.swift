//
//  20251021_CreateCarsTableMigration.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 21.10.2025.
//

@_exported import SQLite
import Foundation

class Migration_20251021_CreateCarsTable {
    
    private let migrationName = "20251021_CreateCarsTable"
    private let db: Connection
    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let expensesTable = Table(DatabaseManager.ExpensesTableName)
        let carsRepository = CarRepository(
            db: db,
            tableName: DatabaseManager.CarsTableName,
            expensesTableName: DatabaseManager.ExpensesTableName,
            userSettingsTableName: DatabaseManager.UserSettingsTableName)

        let expensesRepository = ExpensesRepository(db: db, tableName: DatabaseManager.ExpensesTableName)

        do {

            let carsTableCreateCommand = carsRepository.getCreateTableCommand()
            try db.run(carsTableCreateCommand)
            print("Cars table created successfully")

            let addColumnToExpensesCommand = expensesTable.addColumn(Expression<Int64?>("car_id"))
            try db.run(addColumnToExpensesCommand)
            print("car_id column added to expenses table successfully")

            let allExpenses = expensesRepository.fetchAllSessions()
            if (allExpenses.count > 0) {
                
                let now = Date()
                let lastExpense = allExpenses[0]
                let firstExpense = allExpenses.filter({ $0.isInitialRecord == true })[0]

                let defaultCar = Car(
                    name: "My car",
                    selectedForTracking: true,
                    batteryCapacity: nil,
                    expenseCurrency: lastExpense.currency,
                    currentMileage: lastExpense.odometer,
                    initialMileage: firstExpense.odometer,
                    milleageSyncedAt: now,
                    createdAt: now
                )

                let carId = carsRepository.insert(defaultCar)
                for i in 0..<allExpenses.count {
                    let expense = allExpenses[i]
                    expense.carId = carId
                    _ = expensesRepository.updateSession(expense)
                }

                print("All existing expenses (\(allExpenses.count) associated with the default car")
            }

            print("Migration \(migrationName) executed successfully")
        } catch {
            print("Unable to exeucte migration \(migrationName): \(error)")
        }
    }
}
