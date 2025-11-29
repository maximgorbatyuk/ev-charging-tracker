//
//  ChargingViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 11.10.2025.
//

import Foundation

class ChargingViewModel: ObservableObject, IExpenseView {

    @Published var expenses: [Expense] = []

    var statData: SharedStatsData?
    var totalCost: Double = 0.0

    // Average fuel density in kg per gas liter
    let fuelKgPerL = 2.31
    
    private let environment: EnvironmentService
    private let db: DatabaseManager
    private let expensesRepository: ExpensesRepository
    private let plannedMaintenanceRepository: PlannedMaintenanceRepository
    private let notifications: NotificationManager
    private let appVersionChecker: AppVersionChecker

	private var _checkedAppVersionForAppUpdates: Bool? = nil

    private var _selectedCarForExpenses: Car?

    init(
        environment: EnvironmentService = .shared,
        db: DatabaseManager = .shared,
        notifications: NotificationManager = .shared
    ) {
        self.environment = environment
        self.db = db
        self.notifications = notifications

        self.expensesRepository = db.expensesRepository!
        self.plannedMaintenanceRepository = db.plannedMaintenanceRepository!
        self.appVersionChecker = AppVersionChecker(environment: self.environment)

        loadSessions()
    }

    func loadSessions() {
        self._selectedCarForExpenses = self.reloadSelectedCarForExpenses()
        if let car = self._selectedCarForExpenses, let carId = car.id {
            expenses = expensesRepository.fetchAllSessions(carId)
            totalCost = getTotalCost()
        } else {
            expenses = []
            totalCost = 0
        }

        statData = SharedStatsData(
            co2Saved: getCo2Saved(),
            avgConsumptionKWhPer100: getAvgConsumptionKWhPer100(),
            totalChargingSessionsCount: getChargingSessionsCount(),
            totalChargingCost: getTotalChargingCost(),
            oneKmPriceIncludingAllExpenses: calculateOneKilometerCosts(false),
            oneKmPriceBasedOnlyOnCharging: calculateOneKilometerCosts(true),
            lastUpdated: Date())
    }

    // TODO mgorbatyuk: avoid code duplication with saveNewExpense
    func saveChargingSession(_ chargingSessionResult: AddExpenseViewResult) -> Void {

        var carId: Int64? = nil
        let allCars = self.getAllCars()
        let selectedCar = self.selectedCarForExpenses
        var selectedCarForExpense = selectedCar

        if (chargingSessionResult.carId != nil &&
            selectedCar != nil &&
            chargingSessionResult.carId != selectedCar!.id) {
            carId = chargingSessionResult.carId
            selectedCarForExpense = allCars.first(where: { $0.id == carId })
        }

        if (selectedCarForExpense == nil) {
            if (chargingSessionResult.carName == nil) {

                // TODO mgorbatyuk: show error alert to user
                print("Error: First expense must have a car name!")
                return
            }

            let now = Date()
            let car = Car(
                id: nil,
                name: chargingSessionResult.carName!,
                selectedForTracking: true,
                batteryCapacity: chargingSessionResult.batteryCapacity,
                expenseCurrency: chargingSessionResult.initialExpenseForNewCar!.currency,
                currentMileage: chargingSessionResult.initialExpenseForNewCar!.odometer,
                initialMileage: chargingSessionResult.initialExpenseForNewCar!.odometer,
                milleageSyncedAt: now,
                createdAt: now)

            carId = db.carRepository!.insert(car)
            chargingSessionResult.initialExpenseForNewCar!.setCarId(carId!)
            self.insertExpense(chargingSessionResult.initialExpenseForNewCar!)
        } else {
            carId = selectedCarForExpense!.id
            selectedCarForExpense!.updateMileage(newMileage: chargingSessionResult.expense.odometer)
            _ = db.carRepository!.updateMilleage(selectedCarForExpense!)
        }

        chargingSessionResult.expense.setCarId(carId)
        self.insertExpense(chargingSessionResult.expense)
    }

    func insertExpense(_ session: Expense) -> Void {
        if let id = expensesRepository.insertSession(session) {
            let newSession = session
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
        if (expenses.count < 1) {
            return 0
        }

        let initialRecord = expenses.first(where: { $0.isInitialRecord })
        let lastRecord = expenses
            .filter({ $0.isInitialRecord == false })
            .sorted(by: { $0.id ?? 0 < $1.id ?? 0 })
            .last

        var totalDistance: Int
        let selectedCarForExpenses = self.selectedCarForExpenses

        if (selectedCarForExpenses != nil) {
            totalDistance = selectedCarForExpenses!.getTotalMileage()
        } else {
            totalDistance = (lastRecord?.odometer ?? 0) - (initialRecord?.odometer ?? 0)
        }

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

    func getAllCars() -> [Car] {
        return db.carRepository!.getAllCars()
    }

    func getAddExpenseCurrency() -> Currency {
        if selectedCarForExpenses != nil {
            return selectedCarForExpenses!.expenseCurrency
        }

        return self.db.userSettingsRepository!.fetchCurrency()
    }
    
    func getChargingSessionsCount() -> Int {
        expenses.filter({ $0.isInitialRecord == false && $0.expenseType == .charging }).count
    }

    func getTotalCarDistance() -> Double {
        return Double(selectedCarForExpenses?.getTotalMileage() ?? 0)
    }

    func getAvgConsumptionKWhPer100() -> Double {
        let totalEnergy = self.getTotalEnergy()
        let totalDistance = self.getTotalCarDistance()
        if (totalDistance == 0) {
            return 0.0
        }

        return (totalEnergy / totalDistance) * 100.0
    }

    var selectedCarForExpenses: Car? {
        if (_selectedCarForExpenses == nil) {
            _selectedCarForExpenses = self.reloadSelectedCarForExpenses()
        }

        return _selectedCarForExpenses
    }

    func reloadSelectedCarForExpenses() -> Car? {
        _selectedCarForExpenses = db.carRepository!.getSelectedForExpensesCar()
        return _selectedCarForExpenses
    }

    func getTotalEnergy() -> Double {
        return expenses.reduce(0) { $0 + $1.energyCharged }
    }

    func getCo2Saved() -> Double {
        let co2PerKm = environment.getCo2EuropePollutionPerOneKilometer();
        let totalDistance = self.getTotalCarDistance()
        return co2PerKm * totalDistance
    }

    func getAverageEnergyConsumed() -> Double {
        guard !expenses.isEmpty else { return 0 }
        
        let sessionsToCount = expenses
            .filter({ $0.isInitialRecord == false && $0.expenseType == .charging })
            .count
        
        if (sessionsToCount == 0) {
            return 0
        }

        return getTotalEnergy() / Double(sessionsToCount)
    }

    func getTotalCost() -> Double {
        return expenses
            .filter { $0.isInitialRecord == false }
            .compactMap { $0.cost }.reduce(0, +)
    }

    func getTotalChargingCost() -> Double {
        return expenses
            .filter { $0.isInitialRecord == false && $0.expenseType == .charging }
            .compactMap { $0.cost }.reduce(0, +)
    }

    func tryCheckAppUpdates() -> Void {
        if (_checkedAppVersionForAppUpdates == true) {
            return
        }

        self.appVersionChecker.checkAppStoreVersion() { isUpdateAvailable in
            if (isUpdateAvailable) {
                self.notifications.scheduleAppUpdateNotification()
            }
        }
    }
}
