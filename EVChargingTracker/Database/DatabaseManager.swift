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

    var expensesRepository: ExpensesRepository?
    var migrationRepository: MigrationsRepository?
    var userSettingsRepository: UserSettingsRepository?
    
    private var db: Connection?
    private let latestVersion = 2
    
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

            self.expensesRepository = ExpensesRepository(db: dbConnection)
            self.migrationRepository = MigrationsRepository(db: dbConnection)
            self.userSettingsRepository = UserSettingsRepository(db: dbConnection)

            // Ensure user settings table exists
            self.userSettingsRepository?.createTable()

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
                expensesRepository!.deleteTable()
                expensesRepository!.createTable()

            case 2:
                userSettingsRepository!.createTable()
                userSettingsRepository!.upsertCurrency(Currency.kzt.rawValue)

            default:
                break
            }

            migrationRepository!.addMigrationVersion()
        }
    }
}
