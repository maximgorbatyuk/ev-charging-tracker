//
//  UserSettingsViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import Foundation

class UserSettingsViewModel: ObservableObject {
    @Published var defaultCurrency: Currency
    
    private let db: DatabaseManager
    private let userSettingsRepository: UserSettingsRepository?
    private let expensesRepository: ExpensesRepository

    init() {
        self.db = DatabaseManager.shared
        self.expensesRepository = db.expensesRepository!
        self.userSettingsRepository = db.userSettingsRepository

        self.defaultCurrency = userSettingsRepository?.fetchCurrency() ?? .kzt
    }

    func hasAnyExpense() -> Bool {
        return expensesRepository.expensesCount() > 0
    }

    func getDefaultCurrency() -> Currency {
        return defaultCurrency
    }

    func saveDefaultCurrency(_ currency: Currency) {
        // update in-memory value first so UI updates
        DispatchQueue.main.async {
            self.defaultCurrency = currency
        }

        // persist to DB (upsert)
        let success = userSettingsRepository?.upsertCurrency(currency.rawValue) ?? false
        if !success {
            print("Failed to save default currency to DB")
        }
    }

    func getCars() -> [CarViewModel] {
        let cars = db.carRepository?.getAllCars() ?? []
        return cars.map { car in
            CarViewModel(
                id: car.id ?? 0,
                name: car.name,
                selectedForTracking: car.selectedForTracking,
                batteryCapacity: car.batteryCapacity
            )
        }
    }

    func getCarsCount() -> Int {
        return db.carRepository?.getCarsCount() ?? 0
    }
}

struct CarViewModel: Identifiable {
    let id: Int64
    let name: String
    let selectedForTracking: Bool
    let batteryCapacity: Double?
}
