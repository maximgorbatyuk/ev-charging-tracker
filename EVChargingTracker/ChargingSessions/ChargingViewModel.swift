//
//  ChargingViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 11.10.2025.
//

import Foundation

class ChargingViewModel: ObservableObject, IExpenseView {

    @Published var expenses: [Expense] = []

    let defaultCurrency: Currency
    
    private let db: DatabaseManager
    private let expensesRepository: ExpensesRepository

    init() {
        
        self.db = DatabaseManager.shared
        self.expensesRepository = db.expensesRepository!

        self.defaultCurrency = self.db.userSettingsRepository!.fetchCurrency()

        loadSessions()
    }

    func loadSessions() {
        expenses = expensesRepository.fetchAllSessions()
    }

    func addExpense(_ session: Expense) {
        if let id = expensesRepository.insertSession(session) {
            var newSession = session
            newSession.id = id
            expenses.insert(newSession, at: 0)
        }
    }
    
    func deleteSession(_ session: Expense) {
        guard let sessionId = session.id else { return }
        
        if expensesRepository.deleteSession(id: sessionId) {
            expenses.removeAll { $0.id == sessionId }
        }
    }
    
    func updateSession(_ session: Expense) {
        if expensesRepository.updateSession(session) {
            if let index = expenses.firstIndex(where: { $0.id == session.id }) {
                expenses[index] = session
            }

            loadSessions() // Reload to get proper sorting
        }
    }

    func calculateOneKilometerCosts(_ onlyCharging: Bool) -> Double {
        if (expenses.count < 2) {
            return 0
        }

        let initialRecord = expenses.first(where: { $0.isInitialRecord })
        let lastRecord = expenses
            .filter({ $0.isInitialRecord == false })
            .sorted(by: { $0.id ?? 0 < $1.id ?? 0 })
            .last

        let totalDistance = (lastRecord?.odometer ?? 0) - (initialRecord?.odometer ?? 0)
        if (totalDistance <= 0) {
            return 0
        }

        let expensesToBeConsidered = onlyCharging
            ? expenses.filter({ $0.isInitialRecord == false && $0.expenseType == .charging })
            : expenses.filter { $0.isInitialRecord == false }

        let totalCost = expensesToBeConsidered
            .compactMap { $0.cost }.reduce(0.0, +)

        return totalCost / Double(totalDistance)
    }
    
    func getDefaultCurrency() -> Currency {
        return defaultCurrency
    }
    
    func getChargingSessionsCount() -> Int {
        expenses.filter({ $0.isInitialRecord == false && $0.expenseType == .charging }).count
    }
    
    var totalEnergy: Double {
        expenses.reduce(0) { $0 + $1.energyCharged }
    }
    
    var averageEnergy: Double {
        guard !expenses.isEmpty else { return 0 }
        
        let sessionsToCount = expenses
            .filter({ $0.isInitialRecord == false && $0.expenseType == .charging })
            .count

        return totalEnergy / Double(sessionsToCount)
    }

    var totalCost: Double {
        expenses
            .filter { $0.isInitialRecord == false && $0.expenseType == .charging }
            .compactMap { $0.cost }.reduce(0, +)
    }
}
