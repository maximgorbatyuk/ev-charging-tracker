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
    @Published var selectedFilter: ExpensesFilter = .all
    @Published var currentPage: Int = 1
    @Published var totalRecords: Int = 0
    @Published var totalPages: Int = 0
    @Published var selectedSortingOption: ExpensesSortingOption = .creationDate

    var totalCost: Double = 0.0
    var hasAnyExpense = false
    
    let pageSize: Int = 15

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

        // Load saved sorting preference
        self.selectedSortingOption = db.userSettingsRepository?.fetchExpensesSortingOption() ?? .creationDate

        loadSessions()
    }

    func loadSessions() {
        currentPage = 1
        loadSessionsForCurrentPage()
    }

    func setFilter(_ filter: ExpensesFilter) {
        guard filter != selectedFilter else {
            return
        }

        selectedFilter = filter
        currentPage = 1
        loadSessionsForCurrentPage()

        analytics.trackEvent(
            "expenses_filter_changed",
            properties: [
                "screen": analyticsScreenName,
                "filter": filter.rawValue
            ])
    }

    func setSortingOption(_ option: ExpensesSortingOption) -> Void {
        guard option != selectedSortingOption else {
            return
        }

        selectedSortingOption = option
        currentPage = 1 // Reset to first page when changing sort order

        // Persist to database only if not the default option
        if option != .creationDate {
            db.userSettingsRepository?.upsertExpensesSortingOption(option)
        } else {
            // Remove the setting when returning to default
            db.userSettingsRepository?.upsertExpensesSortingOption(option)
        }

        loadSessionsForCurrentPage()

        analytics.trackEvent(
            "expenses_sorting_changed",
            properties: [
                "screen": analyticsScreenName,
                "sorting_option": option.rawValue
            ])
    }
    
    private func loadSessionsForCurrentPage() -> Void {
        let car = self.reloadSelectedCarForExpenses()
        if let car = car, let carId = car.id {
            hasAnyExpense = (db.expensesRepository?.expensesCount(carId) ?? 0) > 0

            // Get total count for current filters
            totalRecords = chargingSessionsRepository.getExpensesCount(
                carId: carId,
                expenseTypeFilters: selectedFilter.expenseTypes
            )
            
            // Calculate total pages
            totalPages = totalRecords > 0 ? (totalRecords + pageSize - 1) / pageSize : 0
            
            // Ensure current page is within bounds
            if currentPage > totalPages && totalPages > 0 {
                currentPage = totalPages
            }
            if currentPage < 1 {
                currentPage = 1
            }

            // Fetch paginated expenses
            expenses = chargingSessionsRepository.fetchCarSessionsPaginated(
                carId: carId,
                expenseTypeFilters: selectedFilter.expenseTypes,
                page: currentPage,
                pageSize: pageSize,
                sortBy: selectedSortingOption
            )
            totalCost = getTotalCost()
        } else {
            hasAnyExpense = false
            expenses = []
            totalRecords = 0
            totalPages = 0
        }
    }
    
    func goToNextPage() -> Void {
        if currentPage < totalPages {
            currentPage += 1
            loadSessionsForCurrentPage()
            
            analytics.trackEvent(
                "expenses_page_next",
                properties: [
                    "screen": analyticsScreenName,
                    "page": currentPage
                ])
        }
    }
    
    func goToPreviousPage() -> Void {
        if currentPage > 1 {
            currentPage -= 1
            loadSessionsForCurrentPage()
            
            analytics.trackEvent(
                "expenses_page_previous",
                properties: [
                    "screen": analyticsScreenName,
                    "page": currentPage
                ])
        }
    }

    func getAllCars() -> [Car] {
        return db.carRepository!.getAllCars()
    }

    func updateExistingExpense(_ expenseEditResult: AddExpenseViewResult, expenseToEdit: Expense) -> Void {
        expenseToEdit.cost = expenseEditResult.expense.cost
        expenseToEdit.date = expenseEditResult.expense.date
        expenseToEdit.notes = expenseEditResult.expense.notes

        self.updateSession(expenseToEdit)
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
                try newExpenseResult.initialExpenseForNewCar!.setCarIdWithNoValidation(carId!)
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
            try newExpenseResult.expense.setCarIdWithNoValidation(carId)
        } catch {
            logger.error("Error setting car ID for new expense: \(error.localizedDescription)")
            return
        }

        self.insertExpense(newExpenseResult.expense)

        loadSessionsForCurrentPage()

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
            loadSessionsForCurrentPage() // Reload to update pagination
        }
    }
    
    func updateSession(_ session: Expense) {
        if chargingSessionsRepository.updateSession(session) {
            if let index = expenses.firstIndex(where: { $0.id == session.id }) {
                expenses[index] = session
            }

            loadSessionsForCurrentPage() // Reload to reflect updates
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
        guard let car = selectedCarForExpenses,
              let carId = car.id
        else {
            return 0
        }

        return chargingSessionsRepository.getTotalCost(
            carId: carId,
            expenseTypeFilters: selectedFilter.expenseTypes)
    }

    var selectedCarForExpenses: Car? {
        if (_selectedCarForExpenses == nil) {
            _selectedCarForExpenses = self.reloadSelectedCarForExpenses()
        }

        return _selectedCarForExpenses
    }
}
