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

    var chargingSessionsRepository: ChargingSessionsRepository?
    var migrationRepository: MigrationsRepository?
    
    private var db: Connection?
    private let latestVersion = 1
    
    private init() {
       
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            
            let dbPath = "\(path)/tesla_charging.sqlite3"
            print("Database path: \(dbPath)")

            self.db = try Connection(dbPath)
            guard let dbConnection = db else {
                return
            }

            self.chargingSessionsRepository = ChargingSessionsRepository(db: dbConnection)
            self.migrationRepository = MigrationsRepository(db: dbConnection)

            migrateIfNeeded()
        } catch {
            print("Unable to setup database: \(error)")
        }
    }

    func migrateIfNeeded() {

        guard let _ = db else { return }
        
        migrationRepository!.createTableIfNotExists()
        let currentVersion = migrationRepository!.getLatestMigrationVersion()

        if (currentVersion == latestVersion) {
            return
        }

        for version in (Int(currentVersion) + 1)...latestVersion {
            switch version {
            case 1:
                chargingSessionsRepository!.deleteTable()
                chargingSessionsRepository!.createTable()
            default:
                break
            }

            migrationRepository!.addMigrationVersion()
        }
    }
}
