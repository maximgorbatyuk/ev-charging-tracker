//
//  ChargingSessionsRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

@_exported import SQLite
import Foundation

class ExpensesRepository {

    // TODO mgorbatyuk: rename the table to "expenses"
    private let chargingSessionsTable: Table

    private let id = Expression<Int64>("id")
    private let date = Expression<Date>("date")
    private let energyCharged = Expression<Double>("energy_charged")
    private let chargerType = Expression<String>("charger_type")
    private let odometer = Expression<Int>("odometer")
    private let cost = Expression<Double?>("cost")
    private let notes = Expression<String>("notes")
    private let isInitialRecord = Expression<Bool>("is_inital_record")
    private let currency = Expression<String>("currency")
    private let expenseType = Expression<String>("expense_type")
    private let carIdColumn = Expression<Int64?>("car_id")

    private var db: Connection
    
    init(db: Connection, tableName: String) {
        self.db = db
        self.chargingSessionsTable = Table(tableName)
    }

    func createTable() -> Void {
        let command = chargingSessionsTable.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(date)
            t.column(energyCharged)
            t.column(chargerType)
            t.column(odometer)
            t.column(cost)
            t.column(notes)
            t.column(isInitialRecord)
            t.column(currency)
            t.column(expenseType)
        }

        do {
            try db.run(command)
            print("Table created successfully")
        } catch {
            print("Unable to create table: \(error)")
        }
    }

    func deleteTable() {
        do {
            try db.run(chargingSessionsTable.drop(ifExists: true))
            print("Table deleted successfully")
        } catch {
            print("Unable to delete table: \(error)")
        }
    }

    func insertSession(_ session: Expense) -> Int64? {
        
        do {
            let insert = chargingSessionsTable.insert(
                date <- session.date,
                energyCharged <- session.energyCharged,
                chargerType <- session.chargerType.rawValue,
                odometer <- session.odometer,
                cost <- session.cost,
                notes <- session.notes,
                isInitialRecord <- session.isInitialRecord,
                currency <- session.currency.rawValue,
                expenseType <- session.expenseType.rawValue,
                carIdColumn <- session.carId
            )
            
            let rowId = try db.run(insert)
            print("Inserted session with id: \(rowId)")
            return rowId
        } catch {
            print("Insert failed: \(error)")
            return nil
        }
    }

    func expensesCount() -> Int {
        do {
            return try db.scalar(chargingSessionsTable.count)
        } catch {
            print("Failed to get expenses count: \(error)")
            return 0
        }
    }

    func fetchAllSessions(_ expenseTypeFilters: [ExpenseType] = []) -> [Expense] {
        
        var sessionsList: [Expense] = []

        var query: QueryType
        if (!expenseTypeFilters.isEmpty) {
            let stringValues = expenseTypeFilters.map { $0.rawValue }
            query = chargingSessionsTable.filter(stringValues.contains(expenseType)).order(id.desc)
        } else {
            query = chargingSessionsTable.order(id.desc)
        }

        do {
            for session in try db.prepare(query) {
                let chargerTypeEnum = ChargerType(rawValue: session[chargerType]) ?? .other
                let currencyEnum = Currency(rawValue: session[currency]) ?? .usd

                let chargingSession = Expense(
                    id: session[id],
                    date: session[date],
                    energyCharged: session[energyCharged],
                    chargerType: chargerTypeEnum,
                    odometer: session[odometer],
                    cost: session[cost],
                    notes: session[notes],
                    isInitialRecord: session[isInitialRecord],
                    expenseType: ExpenseType(rawValue: session[expenseType]) ?? .other,
                    currency: currencyEnum,
                    carId: session[carIdColumn]
                )

                sessionsList.append(chargingSession)
            }
        } catch {
            print("Fetch failed: \(error)")
        }
        
        return sessionsList
    }

    func updateSession(_ session: Expense) -> Bool {
        let sessionId = session.id ?? 0
        let sessionToUpdate = chargingSessionsTable.filter(id == sessionId)
        
        do {
            try db.run(sessionToUpdate.update(
                date <- session.date,
                energyCharged <- session.energyCharged,
                chargerType <- session.chargerType.rawValue,
                odometer <- session.odometer,
                cost <- session.cost,
                notes <- session.notes,
                isInitialRecord <- session.isInitialRecord,
                currency <- session.currency.rawValue,
                expenseType <- session.expenseType.rawValue,
                carIdColumn <- session.carId
            ))
            print("Updated session with id: \(sessionId)")
            return true
        } catch {
            print("Update failed: \(error)")
            return false
        }
    }

    func deleteSession(id sessionId: Int64) -> Bool {
        let sessionToDelete = chargingSessionsTable.filter(id == sessionId)
        
        do {
            try db.run(sessionToDelete.delete())
            print("Deleted session with id: \(sessionId)")
            return true
        } catch {
            print("Delete failed: \(error)")
            return false
        }
    }

    func getTotalEnergy() -> Double {
        do {
            let total = try db.scalar(chargingSessionsTable.select(energyCharged.sum))
            return total ?? 0
        } catch {
            print("Failed to get total energy: \(error)")
            return 0
        }
    }
    
    func getTotalCost() -> Double {
        do {
            let total = try db.scalar(chargingSessionsTable.select(cost.sum))
            return total ?? 0
        } catch {
            print("Failed to get total cost: \(error)")
            return 0
        }
    }
    
    func getSessionCount() -> Int {
        do {
            return try db.scalar(chargingSessionsTable.count)
        } catch {
            print("Failed to get session count: \(error)")
            return 0
        }
    }
}
