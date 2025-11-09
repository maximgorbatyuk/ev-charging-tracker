//
//  MainTabViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 08.11.2025.
//

import Foundation

class MainTabViewModel {
    private let db: DatabaseManager

    init() {
        self.db = DatabaseManager.shared
    }

    func getPendingMaintenanceRecords() -> Int? {
        let selectedCarForExpenses = db.carRepository?.getSelectedForExpensesCar()
        if (selectedCarForExpenses == nil) {
            return nil
        }

        let result = db.plannedMaintenanceRepository?.getPendingMaintenanceRecords(
            carId: selectedCarForExpenses!.id!,
            currentOdometer: selectedCarForExpenses!.currentMileage,
            currentDate: Date()) ?? nil

        return result
    }
}
