//
//  UserSettingsViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import Foundation
import UIKit
import os

@MainActor
class UserSettingsViewModel: ObservableObject {

    static let onboardingCompletedKey = "isOnboardingComplete"

    @Published var defaultCurrency: Currency
    @Published var selectedLanguage: AppLanguage
    @Published var isExporting: Bool = false
    @Published var isImporting: Bool = false
    @Published var exportError: String?
    @Published var importError: String?
    @Published var showImportConfirmation: Bool = false
    @Published var pendingImportURL: URL?
    @Published var importPreviewData: ImportPreviewData?

    private let environment: EnvironmentService
    private let backupService: BackupService
    private let db: DatabaseManager
    private let userSettingsRepository: UserSettingsRepository?
    private let expensesRepository: ExpensesRepository
    private let developerMode: DeveloperModeManager

    private var _allCars: [CarDto] = []
    private let logger: Logger

    init(
        environment: EnvironmentService = .shared,
        db: DatabaseManager = .shared,
        logger: Logger? = nil,
        developerMode: DeveloperModeManager = .shared,
        backupService: BackupService = .shared
    ) {
        self.environment = environment
        self.db = db
        self.logger = logger ?? Logger(subsystem: "UserSettingsViewModel", category: "Views")
        self.developerMode = developerMode
        self.backupService = backupService

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

    func handleVersionTap() -> Void {
        self.developerMode.handleVersionTap()
    }

    func openAppStoreForUpdate() -> Void {
        let urlAddress = environment.getAppStoreAppLink()
        if let url = URL(string: urlAddress) {
            self.openWebURL(url)
        }
    }

    func openWebURL(_ url: URL) {
        UIApplication.shared.open(url)
    }

    func hasAnyExpense(_ carId: Int64? = nil) -> Bool {
        return expensesRepository.expensesCount(carId) > 0
    }

    func getDefaultCurrency() -> Currency {
        return defaultCurrency
    }

    func saveDefaultCurrency(_ currency: Currency) -> Void {
        // update in-memory value first so UI updates
        DispatchQueue.main.async {
            self.defaultCurrency = currency
        }

        // persist to DB (upsert)
        let success = userSettingsRepository?.upsertCurrency(currency.rawValue) ?? false
        if !success {
            logger.error("Failed to save default currency \(currency.rawValue) to DB")
        }
    }

    // New: save selected language
    func saveLanguage(_ language: AppLanguage) -> Void {
        DispatchQueue.main.async {
            self.selectedLanguage = language
        }

        // Update runtime localization manager so UI can react immediately
        do {
            try LocalizationManager.shared.setLanguage(language)
        }
        catch {
            logger.error("Failed to set language to \(language.rawValue): \(error.localizedDescription)")
        }
        
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

    func isSpecialDeveloperModeEnabled() -> Bool {
        return developerMode.isDeveloperModeEnabled
    }

    func isDevelopmentMode() -> Bool {
        return environment.isDevelopmentMode() ||
                developerMode.isDeveloperModeEnabled
    }

    func deleteAllData() -> Void {
        if (!isDevelopmentMode()) {
            self.logger.info("Attempt to delete all data in non-development mode. Operation aborted.")
            return
        }

        db.deleteAllData()
        refetchCars()
    }

    func deleteAllExpenses() -> Void {
        if (!isDevelopmentMode()) {
            self.logger.info("Attempt to delete all expenses in non-development mode. Operation aborted.")
            return
        }

        let selectedCar = db.carRepository?.getSelectedForExpensesCar()
        if (selectedCar == nil) {
            logger.warning("No car selected for expenses")
            return
        }

        db.deleteAllExpenses(selectedCar!)
        logger.info("Deleted all expenses for car: \(selectedCar!.name)")
    }

    func deleteAllExpensesForCar() -> Void {
        if (!isDevelopmentMode()) {
            self.logger.info("Attempt to delete all data in non-development mode. Operation aborted.")
            return
        }

        let selectedCar = db.carRepository?.getSelectedForExpensesCar()
        if (selectedCar == nil) {
            return
        }

        db.deleteAllExpenses(selectedCar!)
    }

    func addRandomExpenses() -> Void {
        let selectedCar = db.carRepository?.getSelectedForExpensesCar()
        if (selectedCar == nil) {
            return
        }

        let countOfExpenseRecords = 80 // maintenance, carwash, repair
        let countOfChargingSessions = 150
        let countOfPlannedMaintenanceRecords = 20
        let oldestDate = Calendar.current.date(byAdding: .month, value: -8, to: Date())!

        guard let carId = selectedCar!.id else {
            logger.error("Selected car has no ID")
            return
        }
        
        let currency = selectedCar!.expenseCurrency
        let initialMileage = selectedCar!.initialMileage
        let currentMileage = selectedCar!.currentMileage
        
        let currencyValueMultiplier = switch currency {
            case .kzt:
                100.0
            default:
                1.0
        }

        // Helper function to generate random date between oldestDate and now
        func randomDate() -> Date {
            let timeInterval = Date().timeIntervalSince(oldestDate)
            let randomInterval = TimeInterval.random(in: 0...timeInterval)
            return oldestDate.addingTimeInterval(randomInterval)
        }

        // Helper function to generate random odometer value
        func randomOdometer() -> Int {
            return Int.random(in: initialMileage...currentMileage)
        }

        // Generate charging sessions
        logger.info("Adding \(countOfChargingSessions) charging sessions...")
        for i in 0..<countOfChargingSessions {
            let date = randomDate()
            let energyCharged = Double.random(in: 10...75) // kWh
            let chargerTypes = ChargerType.allCases
            let chargerType = chargerTypes.randomElement() ?? .home7kW
            let odometer = randomOdometer()
            let cost = Double.random(in: 5...50) * currencyValueMultiplier // Cost range
            
            let expense = Expense(
                date: date,
                energyCharged: energyCharged,
                chargerType: chargerType,
                odometer: odometer,
                cost: cost,
                notes: "Random charging session \(i + 1)",
                isInitialRecord: false,
                expenseType: .charging,
                currency: currency,
                carId: carId
            )
            
            _ = expensesRepository.insertSession(expense)
        }
        
        // Generate other expenses (maintenance, carwash, repair, other)
        logger.info("Adding \(countOfExpenseRecords) other expenses...")
        let otherExpenseTypes: [ExpenseType] = [.maintenance, .carwash, .repair, .other]

        for i in 0..<countOfExpenseRecords {
            let date = randomDate()
            let expenseType = otherExpenseTypes.randomElement() ?? .other
            let odometer = randomOdometer()
            
            // Different cost ranges based on type
            let cost: Double = {
                switch expenseType {
                case .maintenance:
                    return Double.random(in: 50...300)
                case .repair:
                    return Double.random(in: 100...1000)
                case .carwash:
                    return Double.random(in: 5...30)
                case .other:
                    return Double.random(in: 10...200)
                case .charging:
                    return Double.random(in: 5...50)
                }
            }()

            let notes: String = {
                switch expenseType {
                case .maintenance:
                    return ["Oil change", "Tire rotation", "Brake inspection", "Filter replacement"].randomElement() ?? "Maintenance"
                case .repair:
                    return ["Battery repair", "Suspension fix", "Brake replacement", "Motor service"].randomElement() ?? "Repair"
                case .carwash:
                    return ["Car wash", "Full detail", "Interior cleaning", "Exterior wash"].randomElement() ?? "Car wash"
                case .other:
                    return ["Parking", "Toll", "Insurance", "Registration"].randomElement() ?? "Other"
                case .charging:
                    return "Charging"
                }
            }()

            let expense = Expense(
                date: date,
                energyCharged: 0, // No energy for non-charging expenses
                chargerType: .other,
                odometer: odometer,
                cost: cost * currencyValueMultiplier,
                notes: "\(notes) (\(i + 1))",
                isInitialRecord: false,
                expenseType: expenseType,
                currency: currency,
                carId: carId
            )
            
            _ = expensesRepository.insertSession(expense)
        }
        
        // Generate planned maintenance records
        logger.info("Adding \(countOfPlannedMaintenanceRecords) planned maintenance records...")
        let maintenanceNames = [
            "Tire rotation",
            "Brake fluid change",
            "Cabin air filter replacement",
            "Tire replacement",
            "Brake inspection",
            "Coolant system check",
            "Battery health check",
            "Wheel alignment",
            "Wiper blade replacement",
            "12V battery replacement"
        ]
        
        for i in 0..<countOfPlannedMaintenanceRecords {
            let name = maintenanceNames.randomElement() ?? "Scheduled maintenance"
            
            // Randomly choose between date-based or odometer-based reminder
            let useDateReminder = Bool.random()
            let useOdometerReminder = Bool.random()

            let whenDate: Date? = useDateReminder ? Date().addingTimeInterval(TimeInterval.random(in: 86400...7776000)) : nil // 1 day to 90 days
            let odometerValue: Int? = useOdometerReminder ? currentMileage + Int.random(in: 5000...20000) : nil
            
            let notes = [
                "Important maintenance",
                "Scheduled service",
                "Recommended by manufacturer",
                "Regular checkup",
                "Safety check"
            ].randomElement() ?? "Maintenance note"
            
            let createdAt = randomDate()

            let maintenance = PlannedMaintenance(
                id: nil,
                when: whenDate,
                odometer: odometerValue,
                name: name,
                notes: "\(notes) (\(i + 1))",
                carId: carId,
                createdAt: createdAt
            )
            
            _ = db.plannedMaintenanceRepository?.insertRecord(maintenance)
        }
        
        logger.info("Successfully added random test data: \(countOfChargingSessions) charging sessions, \(countOfExpenseRecords) expenses, \(countOfPlannedMaintenanceRecords) planned maintenance records")
    }

    var allCars : [CarDto] {
        return _allCars
    }

    // MARK: - Export/Import

    func exportData() async -> URL? {
        isExporting = true
        exportError = nil

        do {
            let fileURL = try await backupService.exportData()
            isExporting = false
            logger.info("Export successful: \(fileURL.path)")
            return fileURL
        } catch {
            isExporting = false
            exportError = error.localizedDescription
            logger.error("Export failed: \(error.localizedDescription)")
            return nil
        }
    }

    func prepareImport(from fileURL: URL) async {
        isImporting = true
        importError = nil

        do {
            let exportData = try await backupService.parseExportFile(fileURL)

            // Validate data
            try backupService.validateExportData(exportData)

            // Create preview data
            let preview = ImportPreviewData(
                deviceName: exportData.metadata.deviceName,
                exportDate: exportData.metadata.createdAt,
                appVersion: exportData.metadata.appVersion,
                schemaVersion: exportData.metadata.databaseSchemaVersion,
                carsCount: exportData.cars.count,
                expensesCount: exportData.expenses.count,
                maintenanceCount: exportData.plannedMaintenance.count,
                notificationsCount: exportData.delayedNotifications.count,
                dateRange: calculateDateRange(from: exportData.expenses)
            )

            isImporting = false
            importPreviewData = preview
            pendingImportURL = fileURL
            showImportConfirmation = true
        } catch {
            isImporting = false
            importError = error.localizedDescription
            logger.error("Import preparation failed: \(error.localizedDescription)")
        }
    }

    func confirmImport() async {
        guard let fileURL = pendingImportURL else {
            logger.error("No pending import URL")
            return
        }

        isImporting = true
        importError = nil
        showImportConfirmation = false

        do {
            try await backupService.importData(from: fileURL)

            isImporting = false
            pendingImportURL = nil
            importPreviewData = nil

            // Refresh all data
            refetchCars()

            logger.info("Import successful")
        } catch {
            isImporting = false
            importError = error.localizedDescription
            logger.error("Import failed: \(error.localizedDescription)")
        }
    }

    func cancelImport() {
        pendingImportURL = nil
        importPreviewData = nil
        showImportConfirmation = false
    }

    private func calculateDateRange(from expenses: [ExportExpense]) -> String {
        guard !expenses.isEmpty else {
            return String(localized: "export.preview.no_expenses")
        }

        let dates = expenses.map { $0.date }
        let earliest = dates.min() ?? Date()
        let latest = dates.max() ?? Date()

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return "\(formatter.string(from: earliest)) - \(formatter.string(from: latest))"
    }
}

// MARK: - Import Preview Data

struct ImportPreviewData {
    let deviceName: String
    let exportDate: Date
    let appVersion: String
    let schemaVersion: Int
    let carsCount: Int
    let expensesCount: Int
    let maintenanceCount: Int
    let notificationsCount: Int
    let dateRange: String
}
