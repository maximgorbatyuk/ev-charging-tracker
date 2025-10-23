//
//  DatabaseManager.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 10.10.2025.
//
@_exported import SQLite
import Foundation

class DatabaseManager {
    
    static let ExpensesTableName = "charging_sessions"
    static let MigrationsTableName = "migrations"
    static let UserSettingsTableName = "user_settings"
    static let CarsTableName = "cars"

    static let shared = DatabaseManager()

    var expensesRepository: ExpensesRepository?
    var migrationRepository: MigrationsRepository?
    var userSettingsRepository: UserSettingsRepository?
    var carRepository: CarRepository?

    private var db: Connection?
    private let latestVersion = 3
    
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

            self.expensesRepository = ExpensesRepository(db: dbConnection, tableName: DatabaseManager.ExpensesTableName)
            self.migrationRepository = MigrationsRepository(db: dbConnection, tableName: DatabaseManager.MigrationsTableName)
            self.userSettingsRepository = UserSettingsRepository(db: dbConnection, tableName: DatabaseManager.UserSettingsTableName)
            self.carRepository = CarRepository(
                db: dbConnection,
                tableName: DatabaseManager.CarsTableName,
                expensesTableName: DatabaseManager.ExpensesTableName,
                userSettingsTableName: DatabaseManager.UserSettingsTableName)

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
                _ = userSettingsRepository!.upsertCurrency(Currency.kzt.rawValue)

            case 3:
                let migration3 = Migration_20251021_CreateCarsTable(db: db!)
                migration3.execute()

            default:
                break
            }

            migrationRepository!.addMigrationVersion()
        }
    }
}
