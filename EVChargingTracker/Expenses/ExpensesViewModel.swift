//
//  ExpensesViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.10.2025.
//

import Foundation
import os

class ExpensesViewModel: ObservableObject, IExpenseView {

    @Published var expenses: [Expense] = []

    var totalCost: Double = 0.0
    var hasAnyExpense = false

    var filterButtons: [FilterButtonItem] = []
    let analyticsScreenName = "all_expenses_screen"

    private let db: DatabaseManager
    private let chargingSessionsRepository: ExpensesRepository
    private let plannedMaintenanceRepository: PlannedMaintenanceRepository

    private let notifications: NotificationManager
    private let analytics: AnalyticsService

    private var _selectedCarForExpenses: Car?
    private let logger: Logger

    init(
        db: DatabaseManager = .shared,
        notifications: NotificationManager = .shared,
        analytics: AnalyticsService = .shared,
        logger: Logger? = nil
    ) {
        self.db = db
        self.notifications = notifications
        self.analytics = analytics
        self.logger = logger ?? Logger(subsystem: "ExpensesViewModel", category: "Views")

        self.chargingSessionsRepository = db.expensesRepository!
        self.plannedMaintenanceRepository = db.plannedMaintenanceRepository!

        self.filterButtons = [
            FilterButtonItem(
                title: L("Filter.All"),
                innerAction: {
                    self.loadSessions([])

                    self.analytics.trackEvent(
                        "expenses_filter_all_selected",
                        properties: [
                            "screen": self.analyticsScreenName
                        ])
                },
                isSelected: true),

            FilterButtonItem(
                title: L("Filter.Charges"),
                innerAction: {
                    self.loadSessions([ExpenseType.charging])

                    self.analytics.trackEvent(
                        "expenses_filter_charges_selected",
                        properties: [
                            "screen": self.analyticsScreenName
                        ])
                },
                isSelected: false),

            FilterButtonItem(
                title: L("Filter.Repair/maintenance"),
                innerAction: {
                    self.loadSessions([ExpenseType.repair, ExpenseType.maintenance])

                    self.analytics.trackEvent(
                        "expenses_filter_maintenance_selected",
                        properties: [
                            "screen": self.analyticsScreenName
                        ])
                },
                isSelected: false),

            FilterButtonItem(
                title: L("Filter.Carwash"),
                innerAction: {
                    self.loadSessions([ExpenseType.carwash])

                    self.analytics.trackEvent(
                        "expenses_filter_carwash_selected",
                        properties: [
                            "screen": self.analyticsScreenName
                        ])
                },
                isSelected: false),
        ]

        loadSessions()
    }

    func loadSessions(_ expenseTypeFilters: [ExpenseType] = []) -> Void {
        let car = self.reloadSelectedCarForExpenses()
        if let car = car, let carId = car.id {
            hasAnyExpense = (db.expensesRepository?.expensesCount(carId) ?? 0) > 0

            expenses = chargingSessionsRepository.fetchCarSessions(
                carId : carId,
                expenseTypeFilters: expenseTypeFilters)
            totalCost = getTotalCost()
        } else {
            hasAnyExpense = false
            expenses = []
        }
    }

    func getAllCars() -> [Car] {
        return db.carRepository!.getAllCars()
    }

    // TODO mgorbatyuk: avoid code duplication with saveChargingSession
    func saveNewExpense(_ newExpenseResult: AddExpenseViewResult) -> Void {

        var carId: Int64? = nil
        let allCars = self.getAllCars()

        var selectedCar = self.selectedCarForExpenses
        var selectedCarForExpense = selectedCar

        if (newExpenseResult.carId != nil &&
            selectedCar != nil &&
            newExpenseResult.carId != selectedCar!.id) {

            carId = newExpenseResult.carId
            selectedCarForExpense = allCars.first(where: { $0.id == carId })
        }

        if (selectedCarForExpense == nil) {
            if (newExpenseResult.carName == nil) {

                // TODO mgorbatyuk: show error alert to user
                logger.error("Error: First expense must have a car name!")
                return
            }

            let now = Date()
            let car = Car(
                id: nil,
                name: newExpenseResult.carName!,
                selectedForTracking: true,
                batteryCapacity: newExpenseResult.batteryCapacity,
                expenseCurrency: newExpenseResult.initialExpenseForNewCar!.currency,
                currentMileage: newExpenseResult.initialExpenseForNewCar!.odometer,
                initialMileage: newExpenseResult.initialExpenseForNewCar!.odometer,
                milleageSyncedAt: now,
                createdAt: now)

            carId = self.addCar(car: car)
            do {
                try newExpenseResult.initialExpenseForNewCar!.setCarId(carId!)
            } catch {
                logger.error("Error setting car ID for initial expense of new car: \(error.localizedDescription)")
                return
            }
            
            self.insertExpense(newExpenseResult.initialExpenseForNewCar!)
        } else {
            carId = selectedCarForExpense!.id
            selectedCarForExpense!.updateMileage(newMileage: newExpenseResult.expense.odometer)
            _ = self.updateMilleage(selectedCarForExpense!)
        }

        do {
            try newExpenseResult.expense.setCarId(carId)
        } catch {
            logger.error("Error setting car ID for new expense: \(error.localizedDescription)")
            return
        }

        self.insertExpense(newExpenseResult.expense)

        loadSessions()

        if (newExpenseResult.expense.expenseType == .maintenance ||
            newExpenseResult.expense.expenseType == .repair) {

            selectedCar = self.reloadSelectedCarForExpenses()
            let countOfMaintenanceRecordsToNotify = plannedMaintenanceRepository.getRecordsCountForOdometerValue(carCurrentMileage: selectedCar!.currentMileage)

            if (countOfMaintenanceRecordsToNotify > 0) {
                let notificationBody = String(format: L("You have %d maintenance task(s) due based on your car's current mileage."), countOfMaintenanceRecordsToNotify)
                _ = notifications.scheduleNotification(
                    title: L("Planned maintenance"),
                    body: notificationBody,
                    afterSeconds: 1)
            }
        }
    }

    func reloadSelectedCarForExpenses() -> Car? {
        _selectedCarForExpenses = db.carRepository!.getSelectedForExpensesCar()
        return _selectedCarForExpenses
    }

    func insertExpense(_ session: Expense) {
        _ = chargingSessionsRepository.insertSession(session)
    }
    
    func updateMilleage(_ car: Car) -> Bool {
        return db.carRepository!.updateMilleage(car)
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

    func getAddExpenseCurrency() -> Currency {
        if (selectedCarForExpenses != nil) {
            return selectedCarForExpenses!.expenseCurrency
        }

        return db.userSettingsRepository!.fetchCurrency()
    }

    func hasAnyCar() -> Bool {
        return db.carRepository!.getCarsCount() > 0
    }

    func addCar(car: Car) -> Int64? {
        return db.carRepository!.insert(car)
    }

    func getTotalCost() -> Double {
        return expenses.compactMap { $0.cost }.reduce(0, +)
    }

    var selectedCarForExpenses: Car? {
        if (_selectedCarForExpenses == nil) {
            _selectedCarForExpenses = self.reloadSelectedCarForExpenses()
        }

        return _selectedCarForExpenses
    }
}
