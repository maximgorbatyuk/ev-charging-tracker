//
//  ExpensesViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.10.2025.
//

import Foundation

class ExpensesViewModel: ObservableObject, IExpenseView {

    @Published var expenses: [Expense] = []

    var defaultCurrency: Currency
    
    private let db: DatabaseManager
    private let chargingSessionsRepository: ExpensesRepository

    private var _selectedCarForExpenses: Car?

    init() {
        
        self.db = DatabaseManager.shared
        self.chargingSessionsRepository = db.expensesRepository!
        self.defaultCurrency = db.userSettingsRepository!.fetchCurrency()

        loadSessions()
    }

    func loadSessions() {
        expenses = chargingSessionsRepository.fetchAllSessions()
    }

    func addExpense(_ session: Expense) {
        if let id = chargingSessionsRepository.insertSession(session) {
            let newSession = session
            newSession.id = id
            expenses.insert(newSession, at: 0)
        }
    }
    
    func deleteSession(_ session: Expense) {
        guard let sessionId = session.id else { return }
        
        if chargingSessionsRepository.deleteSession(id: sessionId) {
            expenses.removeAll { $0.id == sessionId }
        }
    }
    
    func updateSession(_ session: Expense) {
        if chargingSessionsRepository.updateSession(session) {
            if let index = expenses.firstIndex(where: { $0.id == session.id }) {
                expenses[index] = session
            }
            loadSessions() // Reload to get proper sorting
        }
    }

    func getDefaultCurrency() -> Currency {
        self.defaultCurrency = db.userSettingsRepository!.fetchCurrency()
        return defaultCurrency
    }

    func hasAnyCar() -> Bool {
        return db.carRepository!.getCarsCount() > 0
    }

    func addCar(car: Car) -> Int64? {
        return db.carRepository!.insert(car)
    }

    var totalCost: Double {
        expenses.compactMap { $0.cost }.reduce(0, +)
    }
    
    var selectedCarForExpenses: Car? {
        if (_selectedCarForExpenses == nil) {
            _selectedCarForExpenses = db.carRepository!.getSelectedForExpensesCar()
        }

        return _selectedCarForExpenses
    }
}
