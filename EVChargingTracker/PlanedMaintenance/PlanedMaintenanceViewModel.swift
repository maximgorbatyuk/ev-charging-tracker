
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
    
    private let notificationsService: NotificationManagerProtocol
    private let maintenanceRepository: PlannedMaintenanceRepositoryProtocol
    private let delayedNotificationsRepo: DelayedNotificationsRepositoryProtocol
    private let carRepo: CarRepositoryProtocol
    
    private var _selectedCarForExpenses: Car?
    
    // MARK: - Convenience properties for backward compatibility
    var repository: PlannedMaintenanceRepositoryProtocol {
        return maintenanceRepository
    }
    
    var delayedNotificationsRepository: DelayedNotificationsRepositoryProtocol {
        return delayedNotificationsRepo
    }
    
    // MARK: - Production initializer
    init(
        notifications: NotificationManagerProtocol,
        db: DatabaseManagerProtocol
    ) {
        self.notificationsService = notifications

        self.maintenanceRepository = db.getPlannedMaintenanceRepository()
        self.delayedNotificationsRepo = db.getDelayedNotificationsRepository()
        self.carRepo = db.getCarRepository()

        loadData()
    }

    func loadData() -> Void {
        let selectedCar = self.reloadSelectedCarForExpenses()
        if (selectedCar == nil) {
            return
        }

        let now = Date()
        var records = maintenanceRepository.getAllRecords(carId: selectedCar!.id!).map { dbRecord in
            PlannedMaintenanceItem(maintenance: dbRecord, car: selectedCar, now: now)
        }
        
        records.sort()
        DispatchQueue.main.async {
            self.maintenanceRecords = records
        }
    }
    
    func addNewMaintenanceRecord(newRecord: PlannedMaintenance) -> Void {
        let recordId = maintenanceRepository.insertRecord(newRecord)
        
        if (newRecord.when != nil) {
            let notificationId = notificationsService.scheduleNotification(
                title: L("Maintenance reminder"),
                body: newRecord.name,
                on: newRecord.when!)
            
            _ = delayedNotificationsRepo.insertRecord(
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
        _ = maintenanceRepository.deleteRecord(id: recordToDelete.id)

        if recordToDelete.when != nil {
            let delayedNotification = delayedNotificationsRepo.getRecordByMaintenanceId(recordToDelete.id)
            guard let delayedNotification = delayedNotification else {
                return
            }

            notificationsService.cancelNotification(delayedNotification.notificationId)
            _ = delayedNotificationsRepo.deleteRecord(id: delayedNotification.id!)
        }
    }

    func updateMaintenanceRecord(_ record: PlannedMaintenance) {
        _ = maintenanceRepository.updateRecord(record)

        /// Cancel existing notification if any
        if let existingNotification = delayedNotificationsRepo.getRecordByMaintenanceId(record.id!) {
            notificationsService.cancelNotification(existingNotification.notificationId)
            _ = delayedNotificationsRepo.deleteRecord(id: existingNotification.id!)
        }

        /// Schedule new notification if date is set
        if let when = record.when {
            let notificationId = notificationsService.scheduleNotification(
                title: L("Maintenance reminder"),
                body: record.name,
                on: when)

            _ = delayedNotificationsRepo.insertRecord(
                DelayedNotification(
                    when: when,
                    notificationId: notificationId,
                    maintenanceRecord: record.id!,
                    carId: record.carId
                )
            )
        }
    }

    func markMaintenanceAsDone(_ record: PlannedMaintenanceItem) {
        deleteMaintenanceRecord(record)
    }

    func getAllCars() -> [Car] {
        return carRepo.getAllCars()
    }

    func reloadSelectedCarForExpenses() -> Car? {
        _selectedCarForExpenses = carRepo.getSelectedForExpensesCar()
        return _selectedCarForExpenses
    }

    var selectedCarForExpenses: Car? {
        if (_selectedCarForExpenses == nil) {
            _selectedCarForExpenses = reloadSelectedCarForExpenses()
        }

        return _selectedCarForExpenses
    }

    var filteredRecords: [PlannedMaintenanceItem] {
        switch selectedFilter {
        case .all:
            return maintenanceRecords

        case .overdue:
            return maintenanceRecords.filter { isOverdue($0) }

        case .dueSoon:
            return maintenanceRecords.filter { isDueSoon($0) }

        case .scheduled:
            return maintenanceRecords.filter { isScheduled($0) }

        case .byMileage:
            return maintenanceRecords.filter { $0.odometer != nil }

        case .byDate:
            return maintenanceRecords.filter { $0.when != nil }
        }
    }

    func setFilter(_ filter: PlannedMaintenanceFilter) {
        guard filter != selectedFilter else {
            return
        }

        selectedFilter = filter
    }

    /// Overdue: mileage passed target OR date passed
    private func isOverdue(_ item: PlannedMaintenanceItem) -> Bool {
        if let mileageDiff = item.mileageDifference,
           mileageDiff > 0
        {
            return true
        }

        if let daysDiff = item.daysDifference,
           daysDiff < 0
        {
            return true
        }

        return false
    }

    /// Due soon: within 7 days OR within 500 km (not overdue)
    private func isDueSoon(_ item: PlannedMaintenanceItem) -> Bool {
        guard !isOverdue(item) else {
            return false
        }

        if let daysDiff = item.daysDifference,
           daysDiff >= 0,
           daysDiff <= 7
        {
            return true
        }

        if let mileageDiff = item.mileageDifference,
           mileageDiff >= -500,
           mileageDiff <= 0
        {
            return true
        }

        return false
    }

    /// Scheduled: not overdue and not due soon
    private func isScheduled(_ item: PlannedMaintenanceItem) -> Bool {
        return !isOverdue(item) && !isDueSoon(item)
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

    init(maintenance: PlannedMaintenance, car: Car? = nil, now: Date = Date()) {
        self.id = maintenance.id!
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

    static func == (first: PlannedMaintenanceItem, second: PlannedMaintenanceItem) -> Bool {
        return first.when == second.when && first.mileageDifference == second.mileageDifference
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
