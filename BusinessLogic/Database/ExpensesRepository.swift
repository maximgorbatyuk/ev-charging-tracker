//
//  ChargingSessionsRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

@_exported import SQLite
import Foundation
import os

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
    private let logger: Logger
    
    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.chargingSessionsTable = Table(tableName)
        self.logger = logger ?? Logger(subsystem: tableName, category: "Database")
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
            logger.info("Table created successfully")
        } catch {
            logger.error("Unable to create table: \(error)")
        }
    }

    func deleteTable() {
        do {
            try db.run(chargingSessionsTable.drop(ifExists: true))
            logger.info("Table deleted successfully")
        } catch {
            logger.error("Unable to delete table: \(error)")
        }
    }

    func truncateTable() -> Void {
        do {
            try db.run(chargingSessionsTable.delete())
            logger.info("Table truncated successfully")
        } catch {
            logger.error("Unable to truncate table: \(error)")
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
            return rowId
        } catch {
            logger.error("Insert failed: \(error)")
            return nil
        }
    }

    func expensesCount(_ carId: Int64? = nil) -> Int {
        do {
            let query = carId != nil
                ? chargingSessionsTable.filter(carIdColumn == carId)
                : chargingSessionsTable
            return try db.scalar(query.count)
        } catch {
            logger.error("Failed to get expenses count: \(error)")
            return 0
        }
    }
    
    func fetchAllSessions(_ carId: Int64? = nil) -> [Expense] {

        var sessionsList: [Expense] = []
        let query = carId != nil
            ? chargingSessionsTable.filter(carIdColumn == carId).order(id.desc)
            : chargingSessionsTable.order(id.desc)

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
            logger.error("Fetch failed: \(error)")
        }
        
        return sessionsList
    }

    func fetchCarSessions(carId: Int64?, expenseTypeFilters: [ExpenseType] = []) -> [Expense] {

        var sessionsList: [Expense] = []

        var query: QueryType
        if (!expenseTypeFilters.isEmpty) {
            let stringValues = expenseTypeFilters.map { $0.rawValue }
            query = chargingSessionsTable
                .filter(carIdColumn == carId)
                .filter(stringValues.contains(expenseType)).order(id.desc)
        } else {
            query = chargingSessionsTable
                .filter(carIdColumn == carId)
                .order(id.desc)
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
            logger.error("Fetch failed: \(error)")
        }
        
        return sessionsList
    }

    // MARK: - Paginated Fetching
    
    /// Fetches expenses for a car with pagination support
    /// - Parameters:
    ///   - carId: The ID of the car to fetch expenses for
    ///   - expenseTypeFilters: Optional filters for expense types
    ///   - page: The page number (1-indexed)
    ///   - pageSize: Number of items per page
    /// - Returns: Array of expenses for the requested page, ordered by id desc (created_at desc)
    func fetchCarSessionsPaginated(
        carId: Int64?,
        expenseTypeFilters: [ExpenseType] = [],
        page: Int,
        pageSize: Int
    ) -> [Expense] {
        // Validate pagination inputs
        guard page > 0 else {
            logger.error("Invalid page number: \(page). Page must be greater than 0.")
            return []
        }
        
        guard pageSize > 0 else {
            logger.error("Invalid page size: \(pageSize). Page size must be greater than 0.")
            return []
        }
        
        // Calculate offset
        let offset = (page - 1) * pageSize
        
        // Build query using helper
        let query = buildPaginatedQuery(
            carId: carId,
            expenseTypeFilters: expenseTypeFilters,
            limit: pageSize,
            offset: offset
        )
        
        // Fetch and map results using helper
        var sessionsList: [Expense] = []
        do {
            for row in try db.prepare(query) {
                let expense = mapRowToExpense(row)
                sessionsList.append(expense)
            }
        } catch {
            logger.error("Fetch paginated failed: \(error)")
        }
        
        return sessionsList
    }
    
    // MARK: - Private Helpers
    
    /// Builds a paginated query for fetching expenses
    /// - Parameters:
    ///   - carId: The ID of the car to filter by
    ///   - expenseTypeFilters: Optional filters for expense types
    ///   - limit: Maximum number of results to return
    ///   - offset: Number of results to skip
    /// - Returns: A configured query ready for execution
    private func buildPaginatedQuery(
        carId: Int64?,
        expenseTypeFilters: [ExpenseType],
        limit: Int,
        offset: Int
    ) -> QueryType {
        var query = chargingSessionsTable.filter(carIdColumn == carId)
        
        // Apply expense type filters if provided
        if !expenseTypeFilters.isEmpty {
            let stringValues = expenseTypeFilters.map { $0.rawValue }
            query = query.filter(stringValues.contains(expenseType))
        }
        
        // Apply ordering and pagination
        return query
            .order(id.desc)
            .limit(limit, offset: offset)
    }
    
    /// Maps a database row to an Expense object
    /// - Parameter row: The database row to map
    /// - Returns: An Expense object populated with data from the row
    private func mapRowToExpense(_ row: Row) -> Expense {
        let chargerTypeEnum = ChargerType(rawValue: row[chargerType]) ?? .other
        let currencyEnum = Currency(rawValue: row[currency]) ?? .usd
        let expenseTypeEnum = ExpenseType(rawValue: row[expenseType]) ?? .other
        
        return Expense(
            id: row[id],
            date: row[date],
            energyCharged: row[energyCharged],
            chargerType: chargerTypeEnum,
            odometer: row[odometer],
            cost: row[cost],
            notes: row[notes],
            isInitialRecord: row[isInitialRecord],
            expenseType: expenseTypeEnum,
            currency: currencyEnum,
            carId: row[carIdColumn]
        )
    }
    
    /// Gets the total count of expenses for a car with optional filters
    /// - Parameters:
    ///   - carId: The ID of the car
    ///   - expenseTypeFilters: Optional filters for expense types
    /// - Returns: Total count of matching expenses
    func getExpensesCount(carId: Int64?, expenseTypeFilters: [ExpenseType] = []) -> Int {
        do {
            if (!expenseTypeFilters.isEmpty) {
                let stringValues = expenseTypeFilters.map { $0.rawValue }
                let query = chargingSessionsTable
                    .filter(carIdColumn == carId)
                    .filter(stringValues.contains(expenseType))
                return try db.scalar(query.count)
            } else {
                let query = chargingSessionsTable.filter(carIdColumn == carId)
                return try db.scalar(query.count)
            }
        } catch {
            logger.error("Failed to get expenses count: \(error)")
            return 0
        }
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
            return true
        } catch {
            logger.error("Update failed: \(error)")
            return false
        }
    }

    func deleteSession(id sessionId: Int64) -> Bool {
        let sessionToDelete = chargingSessionsTable.filter(id == sessionId)
        
        do {
            try db.run(sessionToDelete.delete())
            return true
        } catch {
            logger.error("Delete failed: \(error)")
            return false
        }
    }

    func getTotalEnergy() -> Double {
        do {
            let total = try db.scalar(chargingSessionsTable.select(energyCharged.sum))
            return total ?? 0
        } catch {
            logger.error("Failed to get total energy: \(error)")
            return 0
        }
    }
    
    func getTotalCost() -> Double {
        do {
            let total = try db.scalar(chargingSessionsTable.select(cost.sum))
            return total ?? 0
        } catch {
            logger.error("Failed to get total cost: \(error)")
            return 0
        }
    }
    
    func getSessionCount() -> Int {
        do {
            return try db.scalar(chargingSessionsTable.count)
        } catch {
            logger.error("Failed to get session count: \(error)")
            return 0
        }
    }

    func deleteRecordsForCar(_ carId: Int64) -> Void {
        let recordsToDelete = chargingSessionsTable.filter(carIdColumn == carId)
        do {
            try db.run(recordsToDelete.delete())
        } catch {
            logger.error("Delete failed: \(error)")
        }
    }

    func updateCarExpensesCurrency(_ car: Car) -> Bool {
        let recordToUpdateQuery = chargingSessionsTable.filter(carIdColumn == car.id)
        do {
            try db.run(recordToUpdateQuery.update(currency <- car.expenseCurrency.rawValue))
            return true
        } catch {
            logger.error("Update failed: \(error)")
            return false
        }
    }
}
