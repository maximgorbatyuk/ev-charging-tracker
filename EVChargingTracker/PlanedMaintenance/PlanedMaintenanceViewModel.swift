
//
//  PlanedMaintenanceViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

import Foundation

class PlanedMaintenanceViewModel: ObservableObject {
    
    @Published var maintenanceRecords: [PlannedMaintenanceItem] = []
    
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
    
    func deleteMaintenanceRecord(_ recordToDelete: PlannedMaintenanceItem) -> Void {
        _ = maintenanceRepository.deleteRecord(id: recordToDelete.id)
        
        if (recordToDelete.when != nil) {
            let delayedNotification = delayedNotificationsRepo.getRecordByMaintenanceId(recordToDelete.id)
            if (delayedNotification == nil) {
                return
            }
            
            notificationsService.cancelNotification(delayedNotification!.notificationId)
            _ = delayedNotificationsRepo.deleteRecord(id: delayedNotification!.id!)
        }
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
