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

    // MARK: - Haptic Feedback

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func triggerErrorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static let onboardingCompletedKey = "isOnboardingComplete"

    @Published var defaultCurrency: Currency
    @Published var selectedLanguage: AppLanguage
    @Published var selectedAppearanceMode: AppearanceMode
    @Published var isExporting: Bool = false
    @Published var isImporting: Bool = false
    @Published var exportError: String?
    @Published var importError: String?
    @Published var showImportConfirmation: Bool = false
    @Published var pendingImportURL: URL?
    @Published var importPreviewData: ImportPreviewData?

    // iCloud Backup
    @Published var isBackingUp: Bool = false
    @Published var backupError: String?
    @Published var lastBackupDate: Date?
    @Published var iCloudBackups: [BackupInfo] = []
    @Published var isLoadingBackups: Bool = false
    @Published var showBackupList: Bool = false

    // Automatic Backup
    @Published var isAutomaticBackupEnabled: Bool = false
    @Published var lastAutomaticBackupDate: Date?

    private let environment: EnvironmentService
    private let backupService: BackupService
    private let backgroundTaskManager: BackgroundTaskManager
    private let db: DatabaseManager
    private let userSettingsRepository: UserSettingsRepository?
    private let expensesRepository: ExpensesRepository?
    private let developerMode: DeveloperModeManager

    private var _allCars: [CarDto] = []
    private let logger: Logger

    init(
        environment: EnvironmentService = .shared,
        db: DatabaseManager = .shared,
        logger: Logger? = nil,
        developerMode: DeveloperModeManager = .shared,
        backupService: BackupService = .shared,
        backgroundTaskManager: BackgroundTaskManager = .shared
    ) {
        self.environment = environment
        self.db = db
        self.logger = logger ?? Logger(subsystem: "UserSettingsViewModel", category: "Views")
        self.developerMode = developerMode
        self.backupService = backupService
        self.backgroundTaskManager = backgroundTaskManager

        self.expensesRepository = db.expensesRepository
        self.userSettingsRepository = db.userSettingsRepository

        self.defaultCurrency = userSettingsRepository?.fetchCurrency() ?? .kzt
        self.selectedLanguage = userSettingsRepository?.fetchLanguage() ?? .en
        self.selectedAppearanceMode = AppearanceManager.shared.currentMode
        self._allCars = db.carRepository?.getAllCars()
            .map {
                CarDto(
                    id: $0.id ?? 0,
                    name: $0.name,
                    selectedForTracking: $0.selectedForTracking,
                    batteryCapacity: $0.batteryCapacity,
                    currentMileage: $0.currentMileage,
                    initialMileage: $0.initialMileage,
                    expenseCurrency: $0.expenseCurrency,
                    frontWheelSize: $0.frontWheelSize,
                    rearWheelSize: $0.rearWheelSize)
            } ?? []

        // Sync automatic backup state from BackgroundTaskManager
        self.isAutomaticBackupEnabled = backgroundTaskManager.isAutomaticBackupEnabled
        self.lastAutomaticBackupDate = backgroundTaskManager.lastAutomaticBackupDate
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
        return (expensesRepository?.expensesCount(carId) ?? 0) > 0
    }

    func getDefaultCurrency() -> Currency {
        return defaultCurrency
    }

    func saveDefaultCurrency(_ currency: Currency) -> Void {
        self.defaultCurrency = currency

        // persist to DB (upsert)
        let success = userSettingsRepository?.upsertCurrency(currency.rawValue) ?? false
        if !success {
            logger.error("Failed to save default currency \(currency.rawValue) to DB")
        }
    }

    // New: save selected language
    func saveLanguage(_ language: AppLanguage) -> Void {
        self.selectedLanguage = language

        // Update runtime localization manager so UI can react immediately
        do {
            try LocalizationManager.shared.setLanguage(language)
        }
        catch {
            logger.error("Failed to set language to \(language.rawValue): \(error.localizedDescription)")
        }

    }

    /// Saves the selected appearance mode to the database and updates the app appearance
    func saveAppearanceMode(_ mode: AppearanceMode) {
        self.selectedAppearanceMode = mode

        /// Update the global appearance manager so the UI reacts immediately
        AppearanceManager.shared.setMode(mode)
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
                expenseCurrency: car.expenseCurrency,
                frontWheelSize: car.frontWheelSize,
                rearWheelSize: car.rearWheelSize
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
        guard let newCarId = db.carRepository?.insert(car) else {
            return nil
        }

        if car.selectedForTracking {
            _ = db.carRepository?.markAllCarsAsNoTracking(carIdToExclude: newCarId)
        }

        self.objectWillChange.send()
        return newCarId
    }

    // Update car editable fields and notify UI to refresh
    func updateCar(car: Car) -> Bool {
        let carUpdateSuccess = db.carRepository?.updateCar(car: car) ?? false
        let carExpensesUpdateSyccess = db.expensesRepository?.updateCarExpensesCurrency(car) ?? false

        if car.selectedForTracking,
           let carId = car.id
        {
            _ = db.carRepository?.markAllCarsAsNoTracking(carIdToExclude: carId)
        }

        if carUpdateSuccess && carExpensesUpdateSyccess {
            self.objectWillChange.send()
        }

        return carUpdateSuccess && carExpensesUpdateSyccess
    }

    func deleteCar(_ carId: Int64, selectedForTracking: Bool) -> Void {
        db.plannedMaintenanceRepository?.deleteRecordsForCar(carId)
        _ = db.carRepository?.delete(id: carId)

        if selectedForTracking {
            if let latestCar = db.carRepository?.getLatestAddedCar(),
               let latestCarId = latestCar.id
            {
                _ = db.carRepository?.markCarAsSelectedForTracking(latestCarId)
            }
        }

        refetchCars()
    }

    func refetchCars() {
        self._allCars = self.db.carRepository?.getAllCars()
            .map {
                CarDto(
                    id: $0.id ?? 0,
                    name: $0.name,
                    selectedForTracking: $0.selectedForTracking,
                    batteryCapacity: $0.batteryCapacity,
                    currentMileage: $0.currentMileage,
                    initialMileage: $0.initialMileage,
                    expenseCurrency: $0.expenseCurrency,
                    frontWheelSize: $0.frontWheelSize,
                    rearWheelSize: $0.rearWheelSize)
            } ?? []
        self.objectWillChange.send()
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
        if !isDevelopmentMode() {
            self.logger.info("Attempt to delete all expenses in non-development mode. Operation aborted.")
            return
        }

        guard let selectedCar = db.carRepository?.getSelectedForExpensesCar() else {
            logger.warning("No car selected for expenses")
            return
        }

        db.deleteAllExpenses(selectedCar)
        logger.info("Deleted all expenses for car: \(selectedCar.name)")
    }

    func deleteAllExpensesForCar() -> Void {
        if !isDevelopmentMode() {
            self.logger.info("Attempt to delete all data in non-development mode. Operation aborted.")
            return
        }

        guard let selectedCar = db.carRepository?.getSelectedForExpensesCar() else {
            return
        }

        db.deleteAllExpenses(selectedCar)
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
            
            _ = expensesRepository?.insertSession(expense)
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
            
            _ = expensesRepository?.insertSession(expense)
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
            triggerSuccessHaptic()
            logger.info("Export successful: \(fileURL.path)")
            return fileURL
        } catch {
            isExporting = false
            exportError = error.localizedDescription
            triggerErrorHaptic()
            logger.error("Export failed: \(error.localizedDescription)")
            return nil
        }
    }

    func prepareImport(from fileURL: URL) async {
        isImporting = true
        importError = nil

        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

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

        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try await backupService.importData(from: fileURL)

            isImporting = false
            pendingImportURL = nil
            importPreviewData = nil

            // Refresh all data
            refetchCars()

            triggerSuccessHaptic()
            logger.info("Import successful")
        } catch {
            isImporting = false
            importError = error.localizedDescription
            triggerErrorHaptic()
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

    // MARK: - iCloud Backup

    func createiCloudBackup() async {
        guard backupService.isiCloudAvailable() else {
            backupError = String(localized: "backup.error.icloud_not_available")
            triggerErrorHaptic()
            return
        }

        isBackingUp = true
        backupError = nil

        do {
            let backupInfo = try await backupService.createiCloudBackup()
            isBackingUp = false
            lastBackupDate = backupInfo.createdAt
            triggerSuccessHaptic()
            logger.info("iCloud backup created successfully")
        } catch {
            isBackingUp = false
            backupError = error.localizedDescription
            triggerErrorHaptic()
            logger.error("iCloud backup failed: \(error.localizedDescription)")
        }
    }

    func loadiCloudBackups() async {
        guard backupService.isiCloudAvailable() else {
            backupError = String(localized: "backup.error.icloud_not_available")
            return
        }

        isLoadingBackups = true
        backupError = nil

        do {
            let backups = try await backupService.listiCloudBackups()
            isLoadingBackups = false
            iCloudBackups = backups

            // Update last backup date
            if let latest = backups.first {
                lastBackupDate = latest.createdAt
            }
        } catch {
            isLoadingBackups = false
            backupError = error.localizedDescription
            logger.error("Failed to load iCloud backups: \(error.localizedDescription)")
        }
    }

    func restoreFromiCloudBackup(_ backupInfo: BackupInfo) async {
        isImporting = true
        importError = nil

        do {
            if backupInfo.isDevBackup && !environment.isDevelopmentMode() {
                throw BackupError.devBackupRestoreOnProdApp
            }

            try await backupService.restoreFromiCloudBackup(backupInfo)
            isImporting = false

            // Refresh all data
            refetchCars()

            triggerSuccessHaptic()
            logger.info("Restored from iCloud backup successfully")
        } catch {
            isImporting = false
            importError = error.localizedDescription
            triggerErrorHaptic()
            logger.error("Failed to restore from iCloud backup: \(error.localizedDescription)")
        }
    }

    func deleteiCloudBackup(_ backupInfo: BackupInfo) async {
        do {
            try await backupService.deleteiCloudBackup(backupInfo)

            // Reload backups
            await loadiCloudBackups()

            triggerSuccessHaptic()
            logger.info("Deleted iCloud backup successfully")
        } catch {
            backupError = error.localizedDescription
            triggerErrorHaptic()
            logger.error("Failed to delete iCloud backup: \(error.localizedDescription)")
        }
    }

    func deleteAlliCloudBackups() async {
        do {
            try await backupService.deleteAlliCloudBackups()

            // Reload backups
            await loadiCloudBackups()

            triggerSuccessHaptic()
            logger.info("Deleted all iCloud backups successfully")
        } catch {
            backupError = error.localizedDescription
            triggerErrorHaptic()
            logger.error("Failed to delete all iCloud backups: \(error.localizedDescription)")
        }
    }

    func isiCloudAvailable() -> Bool {
        return backupService.isiCloudAvailable()
    }

    // MARK: - Automatic Backup

    func toggleAutomaticBackup(_ enabled: Bool) {
        isAutomaticBackupEnabled = enabled
        backgroundTaskManager.isAutomaticBackupEnabled = enabled
        logger.info("Automatic backup \(enabled ? "enabled" : "disabled")")
    }

    func refreshAutomaticBackupState() {
        isAutomaticBackupEnabled = backgroundTaskManager.isAutomaticBackupEnabled
        lastAutomaticBackupDate = backgroundTaskManager.lastAutomaticBackupDate
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
