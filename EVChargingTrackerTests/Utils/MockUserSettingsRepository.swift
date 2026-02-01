//
//  MockUserSettingsRepository.swift
//  EVChargingTrackerTests
//
//  Mock implementation of UserSettingsRepositoryProtocol for testing
//

import Foundation

class MockUserSettingsRepository: UserSettingsRepositoryProtocol {
    var settings: [String: String] = [:]
    var currency: Currency = .usd
    var language: AppLanguage = .en
    var expensesSortingOption: ExpensesSortingOption = .creationDate
    var userId: String? = "test-user-id"

    // Call tracking
    var fetchValueCallCount = 0
    var upsertValueCallCount = 0

    // MARK: - UserSettingsRepositoryProtocol

    func fetchValue(for key: String) -> String? {
        fetchValueCallCount += 1
        return settings[key]
    }

    func upsertValue(key: String, value: String) -> Bool {
        upsertValueCallCount += 1
        settings[key] = value
        return true
    }

    func fetchCurrency() -> Currency {
        return currency
    }

    func upsertCurrency(_ currencyValue: String) -> Bool {
        if let newCurrency = Currency(rawValue: currencyValue) {
            currency = newCurrency
            return true
        }
        return false
    }

    func fetchLanguage() -> AppLanguage {
        return language
    }

    func upsertLanguage(_ languageValue: String) -> Bool {
        if let newLanguage = AppLanguage(rawValue: languageValue) {
            language = newLanguage
            return true
        }
        return false
    }

    func fetchOrGenerateUserId() -> String {
        if let existingId = userId {
            return existingId
        }
        let newId = UUID().uuidString
        userId = newId
        return newId
    }

    func fetchUserId() -> String? {
        return userId
    }

    func fetchExpensesSortingOption() -> ExpensesSortingOption {
        return expensesSortingOption
    }

    func upsertExpensesSortingOption(_ option: ExpensesSortingOption) -> Bool {
        expensesSortingOption = option
        return true
    }

    func fetchAllSettings() -> [UserSettingEntry] {
        var entries: [UserSettingEntry] = []
        var id: Int64 = 1
        for (key, value) in settings {
            entries.append(UserSettingEntry(id: id, key: key, value: value))
            id += 1
        }
        return entries
    }
}
