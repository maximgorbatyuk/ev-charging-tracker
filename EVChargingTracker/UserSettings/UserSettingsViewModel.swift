//
//  UserSettingsViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import Foundation

class UserSettingsViewModel: ObservableObject {
    let defaultCurrency: Currency
    
    private let db: DatabaseManager
    private let expensesRepository: ExpensesRepository

    init() {
        
        self.db = DatabaseManager.shared
        self.expensesRepository = db.expensesRepository!
        
        // TODO mgorbatyuk: take from database
        self.defaultCurrency = .kzt
    }

    func getDefaultCurrency() -> Currency {
        return defaultCurrency
    }

    func saveDefaultCurrency(_ currency: Currency) {
        // TODO mgorbatyuk: Implement saving logic if needed
    }
}
