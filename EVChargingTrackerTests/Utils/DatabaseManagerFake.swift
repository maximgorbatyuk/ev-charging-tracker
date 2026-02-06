//
//  DatabaseManagerFake.swift
//  EVChargingTrackerTests
//
//  Fake implementation of DatabaseManagerProtocol for testing
//

import Foundation

class DatabaseManagerFake: DatabaseManagerProtocol {

    private let maintenanceRepository: PlannedMaintenanceRepositoryProtocol
    private let delayedNotificationsRepository: DelayedNotificationsRepositoryProtocol
    private let carRepository: CarRepositoryProtocol
    private let expensesRepository: ExpensesRepositoryProtocol
    private let userSettingsRepository: UserSettingsRepositoryProtocol

    init(
        maintenanceRepository: PlannedMaintenanceRepositoryProtocol = MockPlannedMaintenanceRepository(),
        delayedNotificationsRepository: DelayedNotificationsRepositoryProtocol = MockDelayedNotificationsRepository(),
        carRepository: CarRepositoryProtocol = MockCarRepository(),
        expensesRepository: ExpensesRepositoryProtocol = MockExpensesRepository(),
        userSettingsRepository: UserSettingsRepositoryProtocol = MockUserSettingsRepository()
    ) {
        self.maintenanceRepository = maintenanceRepository
        self.delayedNotificationsRepository = delayedNotificationsRepository
        self.carRepository = carRepository
        self.expensesRepository = expensesRepository
        self.userSettingsRepository = userSettingsRepository
    }

    func getPlannedMaintenanceRepository() -> PlannedMaintenanceRepositoryProtocol? {
        return maintenanceRepository
    }

    func getDelayedNotificationsRepository() -> DelayedNotificationsRepositoryProtocol? {
        return delayedNotificationsRepository
    }

    func getCarRepository() -> CarRepositoryProtocol? {
        return carRepository
    }

    func getExpensesRepository() -> ExpensesRepositoryProtocol? {
        return expensesRepository
    }

    func getUserSettingsRepository() -> UserSettingsRepositoryProtocol? {
        return userSettingsRepository
    }
}
