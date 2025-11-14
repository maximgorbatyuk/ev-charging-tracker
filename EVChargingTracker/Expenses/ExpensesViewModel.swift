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
    private let plannedMaintenanceRepository: PlannedMaintenanceRepository
    private let notifications: NotificationManager

    private var _selectedCarForExpenses: Car?

    init() {
        
        self.db = DatabaseManager.shared
        self.notifications = NotificationManager.shared

        self.chargingSessionsRepository = db.expensesRepository!
        self.plannedMaintenanceRepository = db.plannedMaintenanceRepository!

        self.defaultCurrency = db.userSettingsRepository!.fetchCurrency()

        loadSessions()
    }

    func loadSessions() {
        expenses = chargingSessionsRepository.fetchAllSessions()
    }

    // TODO mgorbatyuk: avoid code duplication with saveChargingSession
    func saveNewExpense(_ newExpenseResult: AddExpenseViewResult) -> Void {

        var selectedCar = self.selectedCarForExpenses
        var carId: Int64? = nil
        if (selectedCar == nil) {
            if (newExpenseResult.carName == nil) {

                // TODO mgorbatyuk: show error alert to user
                print("Error: First expense must have a car name!")
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
            newExpenseResult.initialExpenseForNewCar!.setCarId(carId!)
            self.insertExpense(newExpenseResult.initialExpenseForNewCar!)
        } else {
            carId = selectedCar!.id
            selectedCar!.updateMileage(newMileage: newExpenseResult.expense.odometer)
            _ = self.updateMilleage(selectedCar!)
        }

        newExpenseResult.expense.setCarId(carId)
        self.insertExpense(newExpenseResult.expense)

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
        if let id = chargingSessionsRepository.insertSession(session) {
            let newSession = session
            newSession.id = id
            expenses.insert(newSession, at: 0)
        }
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
            _selectedCarForExpenses = self.reloadSelectedCarForExpenses()
        }

        return _selectedCarForExpenses
    }
}
