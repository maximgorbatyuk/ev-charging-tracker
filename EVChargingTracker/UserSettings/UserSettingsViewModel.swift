//
//  UserSettingsViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import Foundation

class UserSettingsViewModel: ObservableObject {
    @Published var defaultCurrency: Currency
    @Published var selectedLanguage: AppLanguage

    private let environment: EnvironmentService
    private let db: DatabaseManager
    private let userSettingsRepository: UserSettingsRepository?
    private let expensesRepository: ExpensesRepository

    private var _allCars: [CarDto] = []

    init() {
        self.environment = EnvironmentService.shared
        self.db = DatabaseManager.shared
        self.expensesRepository = db.expensesRepository!
        self.userSettingsRepository = db.userSettingsRepository

        self.defaultCurrency = userSettingsRepository?.fetchCurrency() ?? .kzt
        self.selectedLanguage = userSettingsRepository?.fetchLanguage() ?? .en
        self._allCars = db.carRepository?.getAllCars()
            .map {
                CarDto(
                    id: $0.id ?? 0,
                    name: $0.name,
                    selectedForTracking: $0.selectedForTracking,
                    batteryCapacity: $0.batteryCapacity,
                    currentMileage: $0.currentMileage,
                    initialMileage: $0.initialMileage,
                    expenseCurrency: $0.expenseCurrency)
            } ?? []
    }

    func hasAnyExpense(_ carId: Int64? = nil) -> Bool {
        return expensesRepository.expensesCount(carId) > 0
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

    // New: save selected language
    func saveLanguage(_ language: AppLanguage) {
        DispatchQueue.main.async {
            self.selectedLanguage = language
        }

        let success = userSettingsRepository?.upsertLanguage(language.rawValue) ?? false
        if !success {
            print("Failed to save selected language to DB")
        }

        // Update runtime localization manager so UI can react immediately
        LocalizationManager.shared.setLanguage(language)
    }

    func getCars() -> [CarDto] {
        let cars = db.carRepository?.getAllCars() ?? []
        return cars.map { car in
            CarDto(
                id: car.id ?? 0,
                name: car.name,
                selectedForTracking: car.selectedForTracking,
                batteryCapacity: car.batteryCapacity,
                currentMileage: car.currentMileage,
                initialMileage: car.initialMileage,
                expenseCurrency: car.expenseCurrency
            )
        }
    }

    func hasOtherCars(carIdToExclude: Int64) -> Bool {
        return (db.carRepository?.getCarsCountExcludingId(carIdToExclude) ?? 0) > 0
    }

    func getCarsCount() -> Int {
        return db.carRepository?.getCarsCount() ?? 0
    }

    func getCarById(_ id: Int64) -> Car? {
        return db.carRepository?.getCarById(id)
    }
    
    func insertCar(_ car: Car) -> Int64? {
        let newCarId = db.carRepository?.insert(car)

        if newCarId != nil {
            if (car.selectedForTracking) {
                _ = db.carRepository?.markAllCarsAsNoTracking(carIdToExclude: newCarId!)
            }

            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }

        return newCarId
    }

    // Update car editable fields and notify UI to refresh
    func updateCar(car: Car) -> Bool {
        let carUpdateSuccess = db.carRepository?.updateCar(car: car) ?? false
        let carExpensesUpdateSyccess = db.expensesRepository?.updateCarExpensesCurrency(car) ?? false

        if (car.selectedForTracking) {
            _ = db.carRepository?.markAllCarsAsNoTracking(carIdToExclude: car.id!)
        }

        if carUpdateSuccess && carExpensesUpdateSyccess {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }

        return carUpdateSuccess && carExpensesUpdateSyccess
    }

    func deleteCar(_ carId: Int64, selectedForTracking: Bool) -> Void {
        db.expensesRepository?.deleteRecordsForCar(carId)
        db.plannedMaintenanceRepository?.deleteRecordsForCar(carId)
        _ = db.carRepository?.delete(id: carId)

        if (selectedForTracking) {
            let latestCar = db.carRepository?.getLatestAddedCar()
            if let latestCar = latestCar, let latestCarId = latestCar.id {
                _ = db.carRepository!.markCarAsSelectedForTracking(latestCarId)
            }
        }

        refetchCars()
    }

    func refetchCars() {
        DispatchQueue.main.async {
            self._allCars = self.db.carRepository?.getAllCars()
                .map {
                    CarDto(
                        id: $0.id ?? 0,
                        name: $0.name,
                        selectedForTracking: $0.selectedForTracking,
                        batteryCapacity: $0.batteryCapacity,
                        currentMileage: $0.currentMileage,
                        initialMileage: $0.initialMileage,
                        expenseCurrency: $0.expenseCurrency)
                } ?? []
            self.objectWillChange.send()
        }
    }

    func isDevelopmentMode() -> Bool {
        return environment.isDevelopmentMode()
    }
    
    func deleteAllData() -> Void {
        if (!isDevelopmentMode()) {
            print("Attempt to delete all data in non-development mode. Operation aborted.")
            return
        }

        db.deleteAllData()
    }

    var allCars : [CarDto] {
        return _allCars
    }
}
