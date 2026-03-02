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
    @Published var totalMaintenanceCount: Int = 0
    @Published var documentsPreview: [CarDocument] = []
    @Published var ideasPreview: [Idea] = []

    private let carRepo: CarRepositoryProtocol?
    private let maintenanceRepo: PlannedMaintenanceRepositoryProtocol?
    private let documentsRepo: DocumentsRepositoryProtocol?
    private let ideasRepo: IdeasRepositoryProtocol?
    private let expensesRepo: ExpensesRepositoryProtocol?

    private let previewLimit = 3

    init(db: DatabaseManagerProtocol = DatabaseManager.shared) {
        self.carRepo = db.getCarRepository()
        self.maintenanceRepo = db.getPlannedMaintenanceRepository()
        self.documentsRepo = db.getDocumentsRepository()
        self.ideasRepo = db.getIdeasRepository()
        self.expensesRepo = db.getExpensesRepository()
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
            totalMaintenanceCount = 0
            return
        }

        let now = Date()
        let currentMileage = car.currentMileage

        pendingMaintenanceCount = maintenanceRepo?.getPendingMaintenanceRecords(
            carId: carId,
            currentOdometer: currentMileage,
            currentDate: now
        ) ?? 0

        totalMaintenanceCount = maintenanceRepo?.getFilteredRecordsCount(
            carId: carId,
            filter: .all,
            currentMileage: currentMileage,
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

    func hasOtherCars(carIdToExclude: Int64) -> Bool {
        allCars.contains { $0.id != carIdToExclude }
    }

    func getDefaultCurrency() -> Currency {
        selectedCar?.expenseCurrency ?? .usd
    }

    func getCarById(_ id: Int64) -> Car? {
        carRepo?.getCarById(id)
    }

    func updateCar(_ car: Car) -> Bool {
        let carUpdated = carRepo?.updateCar(car: car) ?? false
        let expensesUpdated = expensesRepo?.updateCarExpensesCurrency(car) ?? false

        if car.selectedForTracking, let carId = car.id {
            _ = carRepo?.selectCarForTracking(carId)
        }

        return carUpdated && expensesUpdated
    }

    func deleteCar(_ carId: Int64) {
        let maintenanceRepo = self.maintenanceRepo
        let docsRepo = self.documentsRepo
        let ideasRepo = self.ideasRepo

        maintenanceRepo?.deleteRecordsForCar(carId)
        docsRepo?.deleteRecordsForCar(carId)
        ideasRepo?.deleteRecordsForCar(carId)
        DocumentService.shared.deleteCarDocuments(carId: carId)
        _ = carRepo?.delete(id: carId)
    }

    func selectCar(_ car: Car) {
        guard let carId = car.id, carId != selectedCar?.id else { return }
        let success = carRepo?.selectCarForTracking(carId) ?? false
        if success {
            loadData()
        }
    }
}
