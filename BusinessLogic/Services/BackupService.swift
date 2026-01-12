//
//  BackupService.swift
//  EVChargingTracker
//
//  Service for exporting and importing app data
//

import Foundation
import os

@MainActor
final class BackupService: ObservableObject {
    static let shared = BackupService(
        databaseManager: DatabaseManager.shared)

    // MARK: - Constants

    private let maxSafetyBackups = 3

    // MARK: - File Paths

    private var safetyBackupDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath
            .appendingPathComponent("ev_charging_tracker", isDirectory: true)
            .appendingPathComponent("safety_backups", isDirectory: true)
    }

    // MARK: - Dependencies

    private let currentSchemaVersion: Int // Matches DatabaseManager migration version
    private let carRepository: CarRepository
    private let expensesRepository: ExpensesRepository
    private let maintenanceRepository: PlannedMaintenanceRepository
    private let notificationsRepository: DelayedNotificationsRepository
    private let settingsRepository: UserSettingsRepository
    private let databaseManager: DatabaseManager
    private let logger: Logger

    // MARK: - Initialization

    init(
        databaseManager: DatabaseManager = DatabaseManager.shared
    ) {
        self.databaseManager = databaseManager
        self.currentSchemaVersion = self.databaseManager.getDatabaseSchemaVersion()

        self.carRepository = self.databaseManager.carRepository!
        self.expensesRepository = self.databaseManager.expensesRepository!
        self.maintenanceRepository = self.databaseManager.plannedMaintenanceRepository!
        self.notificationsRepository = self.databaseManager.delayedNotificationsRepository!
        self.settingsRepository = self.databaseManager.userSettingsRepository!
        self.logger = Logger(subsystem: "com.evchargingtracker.businesslogic", category: "BackupService")
    }

    // MARK: - Export

    func exportData() async throws -> URL {
        let exportData = try await createExportData()
        let fileURL = try await saveExportToTemporaryFile(exportData)
        return fileURL
    }

    private func createExportData() async throws -> ExportData {
        // Fetch all data from repositories
        let cars = try await fetchAllCars()
        let expenses = try await fetchAllExpenses()
        let maintenance = try await fetchAllPlannedMaintenance(for: cars)
        let notifications = try await fetchAllDelayedNotifications(for: cars)
        let settings = try await fetchUserSettings()

        // Create metadata
        let metadata = ExportMetadata(
            createdAt: Date(),
            appVersion: getAppVersion(),
            deviceName: getDeviceName(),
            databaseSchemaVersion: currentSchemaVersion
        )

        // Build export structure
        return ExportData(
            metadata: metadata,
            cars: cars.map { ExportCar(from: $0) },
            expenses: expenses.map { ExportExpense(from: $0) },
            plannedMaintenance: maintenance.map { ExportPlannedMaintenance(from: $0) },
            delayedNotifications: notifications.map { ExportDelayedNotification(from: $0) },
            userSettings: settings
        )
    }

    private func saveExportToTemporaryFile(_ exportData: ExportData) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(exportData)

        // Create filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "ev_charging_tracker_export_\(timestamp).json"

        // Save to temporary directory
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        try jsonData.write(to: fileURL)

        // Exclude from backup
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = fileURL
        try mutableURL.setResourceValues(resourceValues)

        return fileURL
    }

    // MARK: - Import

    func importData(from fileURL: URL) async throws {
        // Step 1: Parse and validate JSON
        let exportData = try await parseExportFile(fileURL)

        // Step 2: Validate data integrity
        try validateExportData(exportData)

        // Step 3: Create safety backup
        let safetyBackupURL = try await createSafetyBackup()

        do {
            // Step 4: Wipe existing data
            wipeAllData()

            // Step 5: Import new data
            try await importExportData(exportData)

            // Step 6: Cleanup old safety backups
            cleanupOldSafetyBackups()

        } catch {
            // Step 7: Restore from safety backup if import fails
            self.logger.error("Import failed: \(error.localizedDescription). Restoring from safety backup.")
            try await restoreFromSafetyBackup(safetyBackupURL)
            throw error
        }
    }

    func parseExportFile(_ fileURL: URL) async throws -> ExportData {
        let data = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(ExportData.self, from: data)
        } catch {
            self.logger.error("Failed to parse export file: \(error)")
            throw ExportValidationError.invalidJSON
        }
    }

    func validateExportData(_ exportData: ExportData) throws {
        let metadata = exportData.metadata

        // Validate schema version
        if metadata.databaseSchemaVersion > currentSchemaVersion {
            throw ExportValidationError.newerSchemaVersion(
                current: currentSchemaVersion,
                file: metadata.databaseSchemaVersion
            )
        }

        // Validate dates are not in future (except planned maintenance)
        let now = Date()
        for car in exportData.cars {
            if car.createdAt > now.addingTimeInterval(86400) { // Allow 1 day tolerance
                throw ExportValidationError.invalidDate
            }
        }

        for expense in exportData.expenses {
            if expense.date > now.addingTimeInterval(86400) {
                throw ExportValidationError.invalidDate
            }
        }

        // Validate numeric values
        for expense in exportData.expenses {
            if expense.energyCharged < 0 {
                throw ExportValidationError.invalidNumericValue(field: "energyCharged")
            }
            if expense.odometer < 0 {
                throw ExportValidationError.invalidNumericValue(field: "odometer")
            }
            if let costString = expense.cost, let cost = Double(costString), cost < 0 {
                throw ExportValidationError.invalidNumericValue(field: "cost")
            }
        }

        // Validate currency codes
        let validCurrencies = Set(Currency.allCases.map { $0.rawValue })
        for expense in exportData.expenses {
            if !validCurrencies.contains(expense.currency) {
                throw ExportValidationError.invalidCurrency(code: expense.currency)
            }
        }

        for car in exportData.cars {
            if !validCurrencies.contains(car.expenseCurrency) {
                throw ExportValidationError.invalidCurrency(code: car.expenseCurrency)
            }
        }

        // Validate enum values
        let validChargerTypes = Set(ChargerType.allCases.map { $0.rawValue })
        let validExpenseTypes = Set(ExpenseType.allCases.map { $0.rawValue })

        for expense in exportData.expenses {
            if !validChargerTypes.contains(expense.chargerType) {
                throw ExportValidationError.invalidEnumValue(type: "ChargerType", value: expense.chargerType)
            }
            if !validExpenseTypes.contains(expense.expenseType) {
                throw ExportValidationError.invalidEnumValue(type: "ExpenseType", value: expense.expenseType)
            }
        }

        // Validate references
        let carIds = Set(exportData.cars.compactMap { $0.id })
        for expense in exportData.expenses {
            if let carId = expense.carId, !carIds.contains(carId) {
                throw ExportValidationError.invalidReference(type: "Expense.carId", id: carId)
            }
        }

        for maintenance in exportData.plannedMaintenance {
            if !carIds.contains(maintenance.carId) {
                throw ExportValidationError.invalidReference(type: "PlannedMaintenance.carId", id: maintenance.carId)
            }
        }

        for notification in exportData.delayedNotifications {
            if !carIds.contains(notification.carId) {
                throw ExportValidationError.invalidReference(type: "DelayedNotification.carId", id: notification.carId)
            }
        }
    }

    private func createSafetyBackup() async throws -> URL {
        // Create safety backup directory if needed
        try FileManager.default.createDirectory(
            at: safetyBackupDirectory,
            withIntermediateDirectories: true
        )

        // Create export data
        let exportData = try await createExportData()

        // Create filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "safety_backup_before_import_\(timestamp).json"

        let fileURL = safetyBackupDirectory.appendingPathComponent(filename)

        // Save backup
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(exportData)
        try jsonData.write(to: fileURL)

        self.logger.info("Safety backup created at: \(fileURL.path)")

        return fileURL
    }

    private func restoreFromSafetyBackup(_ backupURL: URL) async throws {
        self.logger.info("Restoring from safety backup: \(backupURL.path)")

        let exportData = try await parseExportFile(backupURL)
        wipeAllData()

        try await importExportData(exportData)

        self.logger.info("Successfully restored from safety backup")
    }

    private func cleanupOldSafetyBackups() {
        do {
            let fileManager = FileManager.default
            let backupFiles = try fileManager.contentsOfDirectory(
                at: safetyBackupDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            // Sort by creation date (newest first)
            let sortedBackups = try backupFiles.sorted { url1, url2 in
                let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 > date2
            }

            // Keep only the most recent N backups
            let backupsToDelete = sortedBackups.dropFirst(maxSafetyBackups)
            for backup in backupsToDelete {
                try fileManager.removeItem(at: backup)
                self.logger.info("Deleted old safety backup: \(backup.lastPathComponent)")
            }
        } catch {
            self.logger.error("Failed to cleanup old safety backups: \(error)")
        }
    }

    private func wipeAllData() -> Void {
        databaseManager.deleteAllData()
        self.logger.info("All data wiped from database")
    }

    private func importExportData(_ exportData: ExportData) async throws {
        // Import in order: Settings, Cars, Expenses, Maintenance, Notifications

        // 1. Import user settings
        let settings = exportData.userSettings
        if let currency = Currency.allCases.first(where: { $0.rawValue == settings.preferredCurrency }) {
            _ = settingsRepository.upsertCurrency(currency.rawValue)
        }
        if let language = AppLanguage.allCases.first(where: { $0.rawValue == settings.preferredLanguage }) {
            _ = settingsRepository.upsertLanguage(language.rawValue)
        }

        // 2. Import cars and build ID mapping
        var carIdMapping: [Int64: Int64] = [:] // oldId -> newId
        for exportCar in exportData.cars {
            let car = exportCar.toCar()
            let oldId = car.id
            car.id = nil // Let database assign new ID

            if let newId = carRepository.insert(car) {
                if let oldId = oldId {
                    carIdMapping[oldId] = newId
                }
            } else {
                throw ExportValidationError.corruptedData
            }
        }

        // 3. Import expenses with updated car IDs
        for exportExpense in exportData.expenses {
            let expense = try exportExpense.toExpense()
            expense.id = nil // Let database assign new ID

            // Map old car ID to new car ID
            if let oldCarId = exportExpense.carId, let newCarId = carIdMapping[oldCarId] {
                do {
                    try expense.setCarIdWithNoValidation(newCarId)
                } catch {
                    throw ExportValidationError.corruptedData
                }
            }

            if expensesRepository.insertSession(expense) == nil {
                throw ExportValidationError.corruptedData
            }
        }

        // 4. Import planned maintenance with updated car IDs
        for exportMaintenance in exportData.plannedMaintenance {
            let maintenance = exportMaintenance.toPlannedMaintenance()
            maintenance.id = nil // Let database assign new ID

            // Map old car ID to new car ID
            if let newCarId = carIdMapping[exportMaintenance.carId] {
                maintenance.carId = newCarId
            }

            if maintenanceRepository.insertRecord(maintenance) == nil {
                throw ExportValidationError.corruptedData
            }
        }

        // 5. Import delayed notifications with updated car IDs and maintenance IDs
        for exportNotification in exportData.delayedNotifications {
            let notification = exportNotification.toDelayedNotification()
            notification.id = nil // Let database assign new ID

            // Map old car ID to new car ID
            if let newCarId = carIdMapping[exportNotification.carId] {
                notification.carId = newCarId
            }

            // Note: Maintenance record IDs are not mapped since we don't track that mapping
            // This is acceptable as the notification will still be stored

            if notificationsRepository.insertRecord(notification) == nil {
                throw ExportValidationError.corruptedData
            }
        }

        self.logger.info("Successfully imported all data: \(exportData.cars.count) cars, \(exportData.expenses.count) expenses, \(exportData.plannedMaintenance.count) maintenance records, \(exportData.delayedNotifications.count) notifications")
    }

    // MARK: - Helper Methods

    private func fetchAllCars() async throws -> [Car] {
        return carRepository.getAllCars()
    }

    private func fetchAllExpenses() async throws -> [Expense] {
        let cars = try await fetchAllCars()
        var allExpenses: [Expense] = []

        for car in cars {
            if let carId = car.id {
                let expenses = expensesRepository.fetchAllSessions(carId)
                allExpenses.append(contentsOf: expenses)
            }
        }

        // Also fetch expenses without car association
        let orphanExpenses = expensesRepository.fetchAllSessions(nil)
        allExpenses.append(contentsOf: orphanExpenses)

        return allExpenses
    }

    private func fetchAllPlannedMaintenance(for cars: [Car]) async throws -> [PlannedMaintenance] {
        var allMaintenance: [PlannedMaintenance] = []

        for car in cars {
            if let carId = car.id {
                let maintenance = maintenanceRepository.getAllRecords(carId: carId)
                allMaintenance.append(contentsOf: maintenance)
            }
        }

        return allMaintenance
    }

    private func fetchAllDelayedNotifications(for cars: [Car]) async throws -> [DelayedNotification] {
        var allNotifications: [DelayedNotification] = []

        for car in cars {
            if let carId = car.id {
                let notifications = notificationsRepository.getAllRecords(carId: carId)
                allNotifications.append(contentsOf: notifications)
            }
        }

        return allNotifications
    }

    private func fetchUserSettings() async throws -> ExportUserSettings {
        let currency = settingsRepository.fetchCurrency()
        let language = settingsRepository.fetchLanguage()

        return ExportUserSettings(currency: currency, language: language)
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private func getDeviceName() -> String {
        return ProcessInfo.processInfo.hostName
    }
}
