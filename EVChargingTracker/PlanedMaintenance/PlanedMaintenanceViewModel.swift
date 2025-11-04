
//
//  PlanedMaintenanceViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

import Foundation

class PlanedMaintenanceViewModel: ObservableObject {

    @Published var maintenanceRecords: [PlannedMaintenanceItem] = []

    private let db: DatabaseManager
    let repository: PlannedMaintenanceRepository

    private var _selectedCarForExpenses: Car?
    
    init() {
        self.db = DatabaseManager.shared
        self.repository = db.plannedMaintenanceRepository!
    }
    
    func loadData() -> Void {
        let selectedCar = self.selectedCarForExpenses
        if (selectedCar == nil) {
            return
        }

        let now = Date()
        var records = repository.getAllRecords(carId: selectedCar!.id!).map { dbRecord in
            PlannedMaintenanceItem(maintenance: dbRecord, car: selectedCar, now: now)
        }

        records.sort()
        DispatchQueue.main.async {
            self.maintenanceRecords = records
        }
    }

    var selectedCarForExpenses: Car? {
        if (_selectedCarForExpenses == nil) {
            _selectedCarForExpenses = db.carRepository!.getSelectedForExpensesCar()
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
                return first.mileageDifference! < second.mileageDifference!
          }

          if (first.when != nil && second.when != nil) {
              return first.when! < second.when!
          }
  
        return first.createdAt < second.createdAt
      }
}
