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
    private let maxiCloudBackups = 5
    private let maxBackupAgeInDays = 30

    // MARK: - File Paths

    private var safetyBackupDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath
            .appendingPathComponent("ev_charging_tracker", isDirectory: true)
            .appendingPathComponent("safety_backups", isDirectory: true)
    }

    private var iCloudBackupDirectory: URL? {
        guard isiCloudAvailable() else {
            logger.warning("iCloud not available - ubiquity identity token is nil")
            return nil
        }

        var bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.evchargingtracker.EVChargingTracker"
        if (bundleIdentifier.contains("Debug")) {
            bundleIdentifier = bundleIdentifier.replacingOccurrences(of: "Debug", with: "")
        }

        let containerIdentifier = "iCloud.\(bundleIdentifier)"

        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) ?? FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            logger.warning("Failed to get iCloud container URL for identifier: \(containerIdentifier)")
            return nil
        }

        return containerURL
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("ev_charging_tracker", isDirectory: true)
            .appendingPathComponent("backups", isDirectory: true)
    }

    // MARK: - Dependencies

    private let currentSchemaVersion: Int // Matches DatabaseManager migration version
    private let carRepository: CarRepository
    private let expensesRepository: ExpensesRepository
    private let maintenanceRepository: PlannedMaintenanceRepository
    private let notificationsRepository: DelayedNotificationsRepository
    private let settingsRepository: UserSettingsRepository
    private let databaseManager: DatabaseManager
    private let networkMonitor: NetworkMonitor
    private let logger: Logger

    // MARK: - Initialization

    init(
        databaseManager: DatabaseManager = DatabaseManager.shared,
        networkMonitor: NetworkMonitor = NetworkMonitor.shared
    ) {
        self.databaseManager = databaseManager
        self.networkMonitor = networkMonitor
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

    // MARK: - iCloud Backup

    func isiCloudAvailable() -> Bool {
        let token = FileManager.default.ubiquityIdentityToken;
        return token != nil
    }

    func checkiCloudStatus() throws {
        guard isiCloudAvailable() else {
            throw BackupError.iCloudNotAvailable
        }

        guard iCloudBackupDirectory != nil else {
            throw BackupError.iCloudNotAvailable
        }

        // Check network connectivity
        guard networkMonitor.checkConnectivity() else {
            logger.warning("Network unavailable for iCloud operation")
            throw BackupError.networkUnavailable
        }
    }

    func createiCloudBackup() async throws -> BackupInfo {
        try checkiCloudStatus()

        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        // Create export data
        let exportData = try await createExportData()

        // Create directory if needed
        try await createiCloudDirectoryIfNeeded()

        // Create filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())

        let isDevelopment = EnvironmentService.shared.isDevelopmentMode()
        let filename = isDevelopment
            ? "ev_charging_tracker_backup_dev_\(timestamp).json"
            : "ev_charging_tracker_backup_\(timestamp).json"

        let fileURL = backupDirectory.appendingPathComponent(filename)

        // Use NSFileCoordinator for safe iCloud access
        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            coordinator.coordinate(
                writingItemAt: fileURL,
                options: .forReplacing,
                error: &coordinatorError
            ) { url in
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    encoder.dateEncodingStrategy = .iso8601

                    let jsonData = try encoder.encode(exportData)
                    try jsonData.write(to: url)

                    self.logger.info("iCloud backup created: \(filename)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to write iCloud backup: \(error)")
                    continuation.resume(throwing: error)
                }
            }

            if let error = coordinatorError {
                continuation.resume(throwing: error)
            }
        }

        // Cleanup old backups
        try await cleanupOldiCloudBackups()

        // Get backup info
        let backupInfo = try getBackupInfo(from: fileURL)
        return backupInfo
    }

    func listiCloudBackups() async throws -> [BackupInfo] {
        try checkiCloudStatus()

        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = NSFileCoordinator()
            var coordinatorError: NSError?

            coordinator.coordinate(
                readingItemAt: backupDirectory,
                options: .withoutChanges,
                error: &coordinatorError
            ) { url in
                do {
                    let fileManager = FileManager.default

                    // Create directory if it doesn't exist
                    if !fileManager.fileExists(atPath: url.path) {
                        try fileManager.createDirectory(
                            at: url,
                            withIntermediateDirectories: true
                        )
                        continuation.resume(returning: [])
                        return
                    }

                    let files = try fileManager.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                        options: [.skipsHiddenFiles]
                    )

                    let jsonFiles = files.filter { $0.pathExtension == "json" }

                    var backups: [BackupInfo] = []
                    for fileURL in jsonFiles {
                        if let info = try? self.getBackupInfo(from: fileURL) {
                            backups.append(info)
                        }
                    }

                    // Sort by creation date (newest first)
                    backups.sort { $0.createdAt > $1.createdAt }

                    continuation.resume(returning: backups)
                } catch {
                    self.logger.error("Failed to list iCloud backups: \(error)")
                    continuation.resume(throwing: error)
                }
            }

            if let error = coordinatorError {
                continuation.resume(throwing: error)
            }
        }
    }

    func restoreFromiCloudBackup(_ backupInfo: BackupInfo) async throws {
        try checkiCloudStatus()

        // Create safety backup before restore
        let safetyBackupURL = try await createSafetyBackup()

        do {
            // Use NSFileCoordinator to read iCloud file
            let exportData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ExportData, Error>) in
                let coordinator = NSFileCoordinator()
                var coordinatorError: NSError?

                coordinator.coordinate(
                    readingItemAt: backupInfo.fileURL,
                    options: .withoutChanges,
                    error: &coordinatorError
                ) { url in
                    do {
                        let data = try Data(contentsOf: url)

                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601

                        let exportData = try decoder.decode(ExportData.self, from: data)
                        continuation.resume(returning: exportData)
                    } catch {
                        self.logger.error("Failed to read iCloud backup: \(error)")
                        continuation.resume(throwing: error)
                    }
                }

                if let error = coordinatorError {
                    continuation.resume(throwing: error)
                }
            }

            // Validate and import
            try validateExportData(exportData)
            wipeAllData()
            try await importExportData(exportData)

            self.logger.info("Successfully restored from iCloud backup: \(backupInfo.fileName)")

        } catch {
            // Restore from safety backup if import fails
            self.logger.error("Restore from iCloud failed: \(error.localizedDescription). Restoring from safety backup.")
            try await restoreFromSafetyBackup(safetyBackupURL)
            throw error
        }
    }

    func deleteiCloudBackup(_ backupInfo: BackupInfo) async throws {
        try checkiCloudStatus()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let coordinator = NSFileCoordinator()
            var coordinatorError: NSError?

            coordinator.coordinate(
                writingItemAt: backupInfo.fileURL,
                options: .forDeleting,
                error: &coordinatorError
            ) { url in
                do {
                    try FileManager.default.removeItem(at: url)
                    self.logger.info("Deleted iCloud backup: \(backupInfo.fileName)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to delete iCloud backup: \(error)")
                    continuation.resume(throwing: error)
                }
            }

            if let error = coordinatorError {
                continuation.resume(throwing: error)
            }
        }
    }

    func deleteAlliCloudBackups() async throws {
        try checkiCloudStatus()

        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        let backups = try await listiCloudBackups()

        guard !backups.isEmpty else {
            return
        }

        for backup in backups {
            try await deleteiCloudBackup(backup)
        }

        self.logger.info("Deleted all iCloud backups: \(backups.count) files")
    }

    private func createiCloudDirectoryIfNeeded() async throws {
        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: backupDirectory.path) {
            try fileManager.createDirectory(
                at: backupDirectory,
                withIntermediateDirectories: true
            )
            self.logger.info("Created iCloud backup directory")
        }
    }

    private func cleanupOldiCloudBackups() async throws {
        guard let backupDirectory = iCloudBackupDirectory else {
            return
        }

        let backups = try await listiCloudBackups()

        // Apply both retention policies
        let now = Date()
        let maxAge = TimeInterval(maxBackupAgeInDays * 24 * 60 * 60)

        var backupsToDelete: [BackupInfo] = []

        // 1. Delete backups older than 30 days
        let oldBackups = backups.filter { now.timeIntervalSince($0.createdAt) > maxAge }
        backupsToDelete.append(contentsOf: oldBackups)

        // 2. Keep only 5 most recent backups
        if backups.count > maxiCloudBackups {
            let excessBackups = backups.dropFirst(maxiCloudBackups)
            backupsToDelete.append(contentsOf: excessBackups)
        }

        // Remove duplicates
        let uniqueBackupsToDelete = Array(Set(backupsToDelete.map { $0.fileURL }))

        // Delete backups
        for fileURL in uniqueBackupsToDelete {
            if let backup = backups.first(where: { $0.fileURL == fileURL }) {
                try? await deleteiCloudBackup(backup)
            }
        }

        if !uniqueBackupsToDelete.isEmpty {
            self.logger.info("Cleaned up \(uniqueBackupsToDelete.count) old iCloud backup(s)")
        }
    }

    private func getBackupInfo(from fileURL: URL) throws -> BackupInfo {
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)

        let creationDate = attributes[.creationDate] as? Date ?? Date()
        let fileSize = attributes[.size] as? Int64 ?? 0

        // Parse metadata from file
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: data)

        return BackupInfo(
            fileName: fileURL.lastPathComponent,
            fileURL: fileURL,
            createdAt: creationDate,
            fileSize: fileSize,
            deviceName: exportData.metadata.deviceName,
            appVersion: exportData.metadata.appVersion,
            schemaVersion: exportData.metadata.databaseSchemaVersion,
            carsCount: exportData.cars.count,
            expensesCount: exportData.expenses.count,
            maintenanceCount: exportData.plannedMaintenance.count,
            notificationsCount: exportData.delayedNotifications.count
        )
    }
}

// MARK: - Backup Models

struct BackupInfo: Identifiable, Hashable {
    let fileName: String
    let fileURL: URL
    let createdAt: Date
    let fileSize: Int64
    let deviceName: String
    let appVersion: String
    let schemaVersion: Int
    let carsCount: Int
    let expensesCount: Int
    let maintenanceCount: Int
    let notificationsCount: Int

    var id: String { fileURL.absoluteString }

    var isDevBackup: Bool { fileName.contains("_dev_") }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fileURL)
    }

    static func == (lhs: BackupInfo, rhs: BackupInfo) -> Bool {
        return lhs.fileURL == rhs.fileURL
    }
}

enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case networkUnavailable
    case iCloudStorageFull
    case devBackupRestoreOnProdApp

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return String(localized: "backup.error.icloud_not_available")
        case .networkUnavailable:
            return String(localized: "backup.error.network_unavailable")
        case .iCloudStorageFull:
            return String(localized: "backup.error.icloud_storage_full")
        case .devBackupRestoreOnProdApp:
            return String(localized: "backup.error.dev_backup_restore_on_prod_app")
        }
    }
}
