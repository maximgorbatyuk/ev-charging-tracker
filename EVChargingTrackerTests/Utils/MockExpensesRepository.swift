//
//  MockExpensesRepository.swift
//  EVChargingTrackerTests
//
//  Mock implementation of ExpensesRepositoryProtocol for testing
//

import Foundation

class MockExpensesRepository: ExpensesRepositoryProtocol {
    var expenses: [Expense] = []
    var insertedExpenses: [Expense] = []
    var updatedExpenses: [Expense] = []
    var deletedExpenseIds: [Int64] = []
    var nextInsertId: Int64 = 1

    // MARK: - ExpensesRepositoryProtocol

    func insertSession(_ session: Expense) -> Int64? {
        insertedExpenses.append(session)
        let id = nextInsertId
        nextInsertId += 1
        return id
    }

    func fetchAllSessions(_ carId: Int64?) -> [Expense] {
        if let carId = carId {
            return expenses.filter { $0.carId == carId }
        }
        return expenses
    }

    func fetchCarSessions(carId: Int64?, expenseTypeFilters: [ExpenseType]) -> [Expense] {
        var result = expenses.filter { $0.carId == carId }
        if !expenseTypeFilters.isEmpty {
            result = result.filter { expenseTypeFilters.contains($0.expenseType) }
        }
        return result
    }

    func fetchCarSessionsPaginated(
        carId: Int64?,
        expenseTypeFilters: [ExpenseType],
        page: Int,
        pageSize: Int,
        sortBy: ExpensesSortingOption
    ) -> [Expense] {
        var result = fetchCarSessions(carId: carId, expenseTypeFilters: expenseTypeFilters)

        switch sortBy {
        case .creationDate:
            result.sort { ($0.id ?? 0) > ($1.id ?? 0) }
        case .odometer:
            result.sort { $0.odometer > $1.odometer }
        }

        let offset = (page - 1) * pageSize
        let end = min(offset + pageSize, result.count)

        guard offset < result.count else { return [] }
        return Array(result[offset..<end])
    }

    func updateSession(_ session: Expense) -> Bool {
        updatedExpenses.append(session)
        return true
    }

    func deleteSession(id sessionId: Int64) -> Bool {
        deletedExpenseIds.append(sessionId)
        return true
    }

    func expensesCount(_ carId: Int64?) -> Int {
        if let carId = carId {
            return expenses.filter { $0.carId == carId }.count
        }
        return expenses.count
    }

    func getExpensesCount(carId: Int64?, expenseTypeFilters: [ExpenseType]) -> Int {
        return fetchCarSessions(carId: carId, expenseTypeFilters: expenseTypeFilters).count
    }

    func getTotalCost(carId: Int64?, expenseTypeFilters: [ExpenseType]) -> Double {
        let filtered = fetchCarSessions(carId: carId, expenseTypeFilters: expenseTypeFilters)
        return filtered.compactMap { $0.cost }.reduce(0, +)
    }

    func getTotalEnergy() -> Double {
        return expenses.reduce(0) { $0 + $1.energyCharged }
    }

    func getTotalCost() -> Double {
        return expenses.compactMap { $0.cost }.reduce(0, +)
    }

    func getSessionCount() -> Int {
        return expenses.count
    }

    func deleteRecordsForCar(_ carId: Int64) {
        expenses.removeAll { $0.carId == carId }
    }

    func updateCarExpensesCurrency(_ car: Car) -> Bool {
        return true
    }
}
