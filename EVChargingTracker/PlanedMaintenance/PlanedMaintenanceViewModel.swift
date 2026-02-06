
//
//  PlanedMaintenanceViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

import Foundation

class PlanedMaintenanceViewModel: ObservableObject {

    @Published var maintenanceRecords: [PlannedMaintenanceItem] = []
    @Published var selectedFilter: PlannedMaintenanceFilter = .all
    @Published var currentPage: Int = 1
    @Published var totalRecords: Int = 0
    @Published var totalPages: Int = 0
    @Published var totalAllRecords: Int = 0

    let pageSize: Int = 10

    let analyticsScreenName = "planned_maintenance_screen"

    private let analytics: AnalyticsService
    private let notificationsService: NotificationManagerProtocol
    private let maintenanceRepository: PlannedMaintenanceRepositoryProtocol?
    private let delayedNotificationsRepo: DelayedNotificationsRepositoryProtocol?
    private let carRepo: CarRepositoryProtocol?
    private let expensesRepo: ExpensesRepositoryProtocol?

    private var _selectedCarForExpenses: Car?

    // MARK: - Convenience properties for backward compatibility
    var repository: PlannedMaintenanceRepositoryProtocol? {
        return maintenanceRepository
    }

    var delayedNotificationsRepository: DelayedNotificationsRepositoryProtocol? {
        return delayedNotificationsRepo
    }

    // MARK: - Production initializer
    init(
        notifications: NotificationManagerProtocol,
        db: DatabaseManagerProtocol,
        analytics: AnalyticsService = .shared
    ) {
        self.notificationsService = notifications
        self.analytics = analytics

        self.maintenanceRepository = db.getPlannedMaintenanceRepository()
        self.delayedNotificationsRepo = db.getDelayedNotificationsRepository()
        self.carRepo = db.getCarRepository()
        self.expensesRepo = db.getExpensesRepository()

        loadData()
    }

    func loadData() {
        guard let selectedCar = self.reloadSelectedCarForExpenses(),
              let carId = selectedCar.id
        else {
            return
        }

        let now = Date()
        let currentMileage = selectedCar.currentMileage

        let allCount = maintenanceRepository?.getFilteredRecordsCount(
            carId: carId,
            filter: .all,
            currentMileage: currentMileage,
            currentDate: now
        ) ?? 0

        let count: Int
        if selectedFilter == .all {
            count = allCount
        } else {
            count = maintenanceRepository?.getFilteredRecordsCount(
                carId: carId,
                filter: selectedFilter,
                currentMileage: currentMileage,
                currentDate: now
            ) ?? 0
        }

        let pages = max(1, Int(ceil(Double(count) / Double(pageSize))))
        if currentPage > pages {
            currentPage = pages
        }

        let records = (maintenanceRepository?.getFilteredRecordsPaginated(
            carId: carId,
            filter: selectedFilter,
            currentMileage: currentMileage,
            currentDate: now,
            page: currentPage,
            pageSize: pageSize
        ) ?? []).compactMap { dbRecord in
            PlannedMaintenanceItem(maintenance: dbRecord, car: selectedCar, now: now)
        }

        DispatchQueue.main.async {
            self.totalAllRecords = allCount
            self.totalRecords = count
            self.totalPages = pages
            self.maintenanceRecords = records
        }
    }
    
    func addNewMaintenanceRecord(newRecord: PlannedMaintenance) -> Void {
        let recordId = maintenanceRepository?.insertRecord(newRecord)
        
        if (newRecord.when != nil) {
            let notificationId = notificationsService.scheduleNotification(
                title: L("Maintenance reminder"),
                body: newRecord.name,
                on: newRecord.when!)
            
            _ = delayedNotificationsRepo?.insertRecord(
                DelayedNotification(
                    when: newRecord.when!,
                    notificationId: notificationId,
                    maintenanceRecord: recordId,
                    carId: newRecord.carId
                )
            )
        }
    }
    
    func deleteMaintenanceRecord(_ recordToDelete: PlannedMaintenanceItem) {
        _ = maintenanceRepository?.deleteRecord(id: recordToDelete.id)

        if recordToDelete.when != nil {
            let delayedNotification = delayedNotificationsRepo?.getRecordByMaintenanceId(recordToDelete.id)
            guard let delayedNotification = delayedNotification else {
                return
            }

            notificationsService.cancelNotification(delayedNotification.notificationId)
            _ = delayedNotificationsRepo?.deleteRecord(id: delayedNotification.id!)
        }
    }

    func updateMaintenanceRecord(_ record: PlannedMaintenance) {
        _ = maintenanceRepository?.updateRecord(record)

        /// Cancel existing notification if any
        if let existingNotification = delayedNotificationsRepo?.getRecordByMaintenanceId(record.id!) {
            notificationsService.cancelNotification(existingNotification.notificationId)
            _ = delayedNotificationsRepo?.deleteRecord(id: existingNotification.id!)
        }

        /// Schedule new notification if date is set
        if let when = record.when {
            let notificationId = notificationsService.scheduleNotification(
                title: L("Maintenance reminder"),
                body: record.name,
                on: when)

            _ = delayedNotificationsRepo?.insertRecord(
                DelayedNotification(
                    when: when,
                    notificationId: notificationId,
                    maintenanceRecord: record.id!,
                    carId: record.carId
                )
            )
        }
    }

    func markMaintenanceAsDone(_ record: PlannedMaintenanceItem, expenseResult: AddExpenseViewResult) {
        /// Save the expense first
        saveExpense(expenseResult)

        /// Then delete the maintenance record
        deleteMaintenanceRecord(record)
    }

    func saveExpense(_ expenseResult: AddExpenseViewResult) {
        /// Handle new car creation if needed
        if let carName = expenseResult.carName,
           expenseResult.carId == nil
        {
            let newCar = Car(
                name: carName,
                selectedForTracking: true,
                batteryCapacity: expenseResult.batteryCapacity,
                expenseCurrency: expenseResult.expense.currency,
                currentMileage: expenseResult.initialOdometr,
                initialMileage: expenseResult.initialOdometr,
                milleageSyncedAt: Date(),
                createdAt: Date()
            )

            if let carId = carRepo?.insert(newCar) {
                expenseResult.expense.carId = carId

                if let initialExpense = expenseResult.initialExpenseForNewCar {
                    initialExpense.carId = carId
                    _ = expensesRepo?.insertSession(initialExpense)
                }
            }
        }

        /// Save the expense
        _ = expensesRepo?.insertSession(expenseResult.expense)

        /// Update car mileage if needed
        if let car = selectedCarForExpenses {
            var updatedCar = car
            updatedCar.currentMileage = expenseResult.expense.odometer
            _ = carRepo?.updateMilleage(updatedCar)
        }
    }

    func getAllCars() -> [Car] {
        return carRepo?.getAllCars() ?? []
    }

    func duplicateMaintenanceRecord(_ record: PlannedMaintenanceItem) {
        let duplicate = PlannedMaintenance(
            when: record.when,
            odometer: record.odometer,
            name: record.name,
            notes: record.notes,
            carId: record.carId
        )

        addNewMaintenanceRecord(newRecord: duplicate)
    }

    func reloadSelectedCarForExpenses() -> Car? {
        _selectedCarForExpenses = carRepo?.getSelectedForExpensesCar()
        return _selectedCarForExpenses
    }

    var selectedCarForExpenses: Car? {
        if (_selectedCarForExpenses == nil) {
            _selectedCarForExpenses = reloadSelectedCarForExpenses()
        }

        return _selectedCarForExpenses
    }

    func setFilter(_ filter: PlannedMaintenanceFilter) {
        guard filter != selectedFilter else {
            return
        }

        selectedFilter = filter
        currentPage = 1
        loadData()
    }

    func goToNextPage() {
        if currentPage < totalPages {
            currentPage += 1

            analytics.trackEvent(
                "maintenance_page_next",
                properties: [
                    "screen": analyticsScreenName,
                    "page": currentPage
                ])

            loadData()
        }
    }

    func goToPreviousPage() {
        if currentPage > 1 {
            currentPage -= 1

            analytics.trackEvent(
                "maintenance_page_previous",
                properties: [
                    "screen": analyticsScreenName,
                    "page": currentPage
                ])

            loadData()
        }
    }

}

// TODO mgorbatyuk: implement date difference in days, propably
struct PlannedMaintenanceItem: Identifiable, Comparable {
    let id: Int64
    let name: String
    let notes: String
    let odometer: Int?
    let when: Date?
    let carId: Int64
    let createdAt: Date

    let mileageDifference: Int?
    let daysDifference: Int?

    init?(maintenance: PlannedMaintenance, car: Car? = nil, now: Date = Date()) {
        guard let maintenanceId = maintenance.id else { return nil }
        self.id = maintenanceId
        self.name = maintenance.name
        self.notes = maintenance.notes
        self.odometer = maintenance.odometer
        self.when = maintenance.when
        self.carId = maintenance.carId
        self.createdAt = maintenance.createdAt

        if let car = car, let odometer = maintenance.odometer {
            self.mileageDifference = car.currentMileage - odometer
        } else {
            self.mileageDifference = nil
        }

        if let when = maintenance.when {
            self.daysDifference = Calendar.current.dateComponents([.day], from: now, to: when).day
        } else {
            self.daysDifference = nil
        }
    }

    static func < (first: PlannedMaintenanceItem, second: PlannedMaintenanceItem) -> Bool {
          if (first.mileageDifference != nil && second.mileageDifference != nil) {
                return first.mileageDifference! > second.mileageDifference!
          }

          if (first.when != nil && second.when != nil) {
              return first.when! < second.when!
          }
          
          if (first.mileageDifference != nil) {
              return true
          }
          
          if (second.mileageDifference != nil) {
              return false
          }
          
          if (first.when != nil) {
              return true
          }
          
          if (second.when != nil) {
              return false
          }

          return first.createdAt < second.createdAt
      }
}
