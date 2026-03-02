//
//  CarDetailsViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation

@MainActor
class CarDetailsViewModel: ObservableObject {

    @Published var selectedCar: Car?
    @Published var allCars: [Car] = []
    @Published var maintenancePreview: [PlannedMaintenanceItem] = []
    @Published var pendingMaintenanceCount: Int = 0
    @Published var documentsPreview: [CarDocument] = []
    @Published var ideasPreview: [Idea] = []

    private let carRepo: CarRepositoryProtocol?
    private let maintenanceRepo: PlannedMaintenanceRepositoryProtocol?
    private let documentsRepo: DocumentsRepositoryProtocol?
    private let ideasRepo: IdeasRepositoryProtocol?

    private let previewLimit = 3

    init(db: DatabaseManagerProtocol = DatabaseManager.shared) {
        self.carRepo = db.getCarRepository()
        self.maintenanceRepo = db.getPlannedMaintenanceRepository()
        self.documentsRepo = db.getDocumentsRepository()
        self.ideasRepo = db.getIdeasRepository()
        loadData()
    }

    func loadData() {
        allCars = carRepo?.getAllCars() ?? []
        selectedCar = carRepo?.getSelectedForExpensesCar()

        loadMaintenancePreview()
        loadDocumentsPreview()
        loadIdeasPreview()
    }

    func loadMaintenancePreview() {
        guard let car = selectedCar, let carId = car.id else {
            maintenancePreview = []
            pendingMaintenanceCount = 0
            return
        }

        let now = Date()
        let currentMileage = car.currentMileage

        pendingMaintenanceCount = maintenanceRepo?.getPendingMaintenanceRecords(
            carId: carId,
            currentOdometer: currentMileage,
            currentDate: now
        ) ?? 0

        let records = maintenanceRepo?.getFilteredRecordsPaginated(
            carId: carId,
            filter: .all,
            currentMileage: currentMileage,
            currentDate: now,
            page: 1,
            pageSize: previewLimit
        ) ?? []

        maintenancePreview = records.compactMap {
            PlannedMaintenanceItem(maintenance: $0, car: car, now: now)
        }.sorted()
    }

    func loadDocumentsPreview() {
        guard let car = selectedCar, let carId = car.id else {
            documentsPreview = []
            return
        }
        documentsPreview = documentsRepo?.getLatestRecords(carId: carId, limit: previewLimit) ?? []
    }

    func loadIdeasPreview() {
        guard let car = selectedCar, let carId = car.id else {
            ideasPreview = []
            return
        }
        ideasPreview = ideasRepo?.getLatestRecords(carId: carId, limit: previewLimit) ?? []
    }

    var hasMultipleCars: Bool {
        allCars.count > 1
    }

    func selectCar(_ car: Car) {
        guard let carId = car.id, carId != selectedCar?.id else { return }
        _ = carRepo?.markAllCarsAsNoTracking(carIdToExclude: carId)
        _ = carRepo?.markCarAsSelectedForTracking(carId)
        loadData()
    }

    var totalMaintenanceCount: Int {
        guard let car = selectedCar, let carId = car.id else { return 0 }
        return maintenanceRepo?.getFilteredRecordsCount(
            carId: carId,
            filter: .all,
            currentMileage: car.currentMileage,
            currentDate: Date()
        ) ?? 0
    }
}
