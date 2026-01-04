@_exported import SQLite
import Foundation
import os

class UserSettingsRepository {
    private let table: Table

    private let id = Expression<Int64>("id")
    private let keyColumn = Expression<String>("key")
    private let valueColumn = Expression<String>("value")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: tableName, category: "Database")
    }

    func createTable() {
        let command = table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(keyColumn)
            t.column(valueColumn)
        }

        do {
            try db.run(command)
        } catch {
            logger.error("Unable to create user_settings table: \(error)")
        }
    }

    func fetchValue(for key: String) -> String? {
        do {
            let query = table.filter(keyColumn == key).limit(1)
            if let row = try db.pluck(query) {
                return row[valueColumn]
            }
        } catch {
            logger.error("Failed to fetch user setting for \(key): \(error)")
        }
        return nil
    }

    func upsertValue(key: String, value: String) -> Bool {
        do {
            let existing = table.filter(keyColumn == key).limit(1)
            if let row = try db.pluck(existing) {
                let rowId = row[id]
                let record = table.filter(id == rowId)
                try db.run(record.update(valueColumn <- value))
                return true
            } else {
                let insert = table.insert(keyColumn <- key, valueColumn <- value)
                try db.run(insert)
                return true
            }
        } catch {
            logger.error("Failed to upsert user setting for \(key): \(error)")
            return false
        }
    }

    // Convenience older API for currency to avoid touching callers immediately
    func fetchCurrencyAsString() -> String? {
        return fetchValue(for: "currency")
    }

    func fetchCurrency() -> Currency {
        if let currencyString = fetchCurrencyAsString(), let currency = Currency(rawValue: currencyString) {
            return currency
        }

        return .kzt // default fallback
    }

    func upsertCurrency(_ currencyValue: String) -> Bool {
        return upsertValue(key: "currency", value: currencyValue)
    }

    // New: language helpers (store language as string code: "en", "ru")
    func fetchLanguageAsString() -> String? {
        return fetchValue(for: "language")
    }

    func fetchLanguage() -> AppLanguage {
        if let langString = fetchLanguageAsString(), let lang = AppLanguage(rawValue: langString) {
            return lang
        }
        return .en
    }

    func upsertLanguage(_ languageValue: String) -> Bool {
        return upsertValue(key: "language", value: languageValue)
    }
    
    /// Fetches the user_id from the database. If no user_id exists, generates a new UUID and stores it.
    /// - Returns: The user_id string (either existing or newly generated)
    func fetchOrGenerateUserId() -> String {
        if let existingUserId = fetchValue(for: "user_id") {
            return existingUserId
        }
        
        // Generate new UUID if no user_id exists
        let newUserId = UUID().uuidString
        _ = upsertValue(key: "user_id", value: newUserId)
        logger.info("Generated new user_id: \(newUserId)")
        return newUserId
    }
    
    /// Fetches the user_id from the database without generating a new one
    /// - Returns: The user_id string or nil if it doesn't exist
    func fetchUserId() -> String? {
        return fetchValue(for: "user_id")
    }
}
