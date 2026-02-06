//
//  MainTabViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 08.11.2025.
//

import Foundation

class MainTabViewModel {
    private let db: DatabaseManager
    private let appVersionChecker: AppVersionCheckerProtocol

    init(
        db: DatabaseManager = .shared,
        appVersionChecker: AppVersionCheckerProtocol
    ) {
        self.db = db
        self.appVersionChecker = appVersionChecker
    }

    func getPendingMaintenanceRecords() -> Int {
        guard let selectedCar = db.carRepository?.getSelectedForExpensesCar(),
              let carId = selectedCar.id
        else {
            return 0
        }

        let result = db.plannedMaintenanceRepository?.getPendingMaintenanceRecords(
            carId: carId,
            currentOdometer: selectedCar.currentMileage,
            currentDate: Date()) ?? 0

        return result
    }

    func checkAppVersion() async -> Bool? {
        return await appVersionChecker.checkAppStoreVersion()
    }
}
