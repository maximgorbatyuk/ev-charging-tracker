//
//  DatabaseManager.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 10.10.2025.
//
@_exported import SQLite
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?
    
    // Table definition
    private let chargingSessionsTable = Table("charging_sessions")

    private let id = Expression<Int64>("id")
    private let date = Expression<Date>("date")
    private let energyCharged = Expression<Double>("energy_charged")
    private let chargerType = Expression<String>("charger_type")
    private let odometer = Expression<Int>("odometer")
    private let cost = Expression<Double?>("cost")
    private let notes = Expression<String>("notes")
    private let isInitalRecord = Expression<Bool>("is_inital_record")
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            
            let dbPath = "\(path)/tesla_charging.sqlite3"
            print("Database path: \(dbPath)")
            
            db = try Connection(dbPath)
            createTable()
        } catch {
            print("Unable to setup database: \(error)")
        }
    }
    
    private func createTable() {
        guard let db = db else { return }
        
        do {
            try db.run(chargingSessionsTable.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(date)
                t.column(energyCharged)
                t.column(chargerType)
                t.column(odometer)
                t.column(cost)
                t.column(notes)
                t.column(isInitalRecord)
            })
            print("Table created successfully")
        } catch {
            print("Unable to create table: \(error)")
        }
    }

    private func deleteTable() {
        guard let db = db else { return }
        
        do {
            try db.run(chargingSessionsTable.drop(ifExists: true))
            print("Table deleted successfully")
        } catch {
            print("Unable to delete table: \(error)")
        }
    }

    // CRUD Operations
    func insertSession(_ session: ChargingSession) -> Int64? {
        guard let db = db else { return nil }
        
        do {
            let insert = chargingSessionsTable.insert(
                date <- session.date,
                energyCharged <- session.energyCharged,
                chargerType <- session.chargerType.rawValue,
                odometer <- session.odometer,
                cost <- session.cost,
                notes <- session.notes,
                isInitalRecord <- session.isInitalRecord
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
        guard let db = db else { return [] }
        
        var sessionsList: [ChargingSession] = []
        
        do {
            for session in try db.prepare(chargingSessionsTable.order(date.desc)) {
                let chargerTypeEnum = ChargerType(rawValue: session[chargerType]) ?? .home7kW
                
                let chargingSession = ChargingSession(
                    id: session[id],
                    date: session[date],
                    energyCharged: session[energyCharged],
                    chargerType: chargerTypeEnum,
                    odometer: session[odometer],
                    cost: session[cost],
                    notes: session[notes],
                    isInitalRecord: session[isInitalRecord]
                )
                sessionsList.append(chargingSession)
            }
        } catch {
            print("Fetch failed: \(error)")
        }
        
        return sessionsList
    }
    
    func updateSession(_ session: ChargingSession) -> Bool {
        guard let db = db, let sessionId = session.id else { return false }
        
        let sessionToUpdate = chargingSessionsTable.filter(id == sessionId)
        
        do {
            try db.run(sessionToUpdate.update(
                date <- session.date,
                energyCharged <- session.energyCharged,
                chargerType <- session.chargerType.rawValue,
                odometer <- session.odometer,
                cost <- session.cost,
                notes <- session.notes,
                isInitalRecord <- session.isInitalRecord
            ))
            print("Updated session with id: \(sessionId)")
            return true
        } catch {
            print("Update failed: \(error)")
            return false
        }
    }
    
    func deleteSession(id sessionId: Int64) -> Bool {
        guard let db = db else { return false }
        
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
        guard let db = db else { return 0 }
        
        do {
            let total = try db.scalar(chargingSessionsTable.select(energyCharged.sum))
            return total ?? 0
        } catch {
            print("Failed to get total energy: \(error)")
            return 0
        }
    }
    
    func getTotalCost() -> Double {
        guard let db = db else { return 0 }
        
        do {
            let total = try db.scalar(chargingSessionsTable.select(cost.sum))
            return total ?? 0
        } catch {
            print("Failed to get total cost: \(error)")
            return 0
        }
    }
    
    func getSessionCount() -> Int {
        guard let db = db else { return 0 }
        
        do {
            return try db.scalar(chargingSessionsTable.count)
        } catch {
            print("Failed to get session count: \(error)")
            return 0
        }
    }
}
