//
//  ChargingSessionsRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

@_exported import SQLite
import Foundation

class ChargingSessionsRepository {
    private let chargingSessionsTable = Table("charging_sessions")

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

    private var db: Connection
    
    init(db: Connection) {
        self.db = db
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

    func insertSession(_ session: ChargingSession) -> Int64? {
        
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
                expenseType <- session.expenseType.rawValue
            )
            
            let rowId = try db.run(insert)
            print("Inserted session with id: \(rowId)")
            return rowId
        } catch {
            print("Insert failed: \(error)")
            return nil
        }
    }
    
    func fetchAllSessions() -> [ChargingSession] {
        
        var sessionsList: [ChargingSession] = []
        
        do {
            for session in try db.prepare(chargingSessionsTable.order(date.desc)) {
                let chargerTypeEnum = ChargerType(rawValue: session[chargerType]) ?? .home7kW
                let currencyEnum = Currency(rawValue: session[currency]) ?? .usd

                let chargingSession = ChargingSession(
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
                )
                sessionsList.append(chargingSession)
            }
        } catch {
            print("Fetch failed: \(error)")
        }
        
        return sessionsList
    }

    func updateSession(_ session: ChargingSession) -> Bool {
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
                expenseType <- session.expenseType.rawValue
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
