//
//  EVChargingTrackerTests.swift
//  EVChargingTrackerTests
//
//  Created by Maxim Gorbatyuk on 08.10.2025.
//

import Testing
@testable import EVChargingTracker

// MARK: - Mock Implementations

class MockPlannedMaintenanceRepository: PlannedMaintenanceRepositoryProtocol {
    var records: [PlannedMaintenance] = []
    var insertedRecords: [PlannedMaintenance] = []
    var deletedRecordIds: [Int64] = []
    var nextInsertId: Int64 = 1
    
    func getAllRecords(carId: Int64) -> [PlannedMaintenance] {
        return records.filter { $0.carId == carId }
    }
    
    func insertRecord(_ record: PlannedMaintenance) -> Int64? {
        insertedRecords.append(record)
        let id = nextInsertId
        nextInsertId += 1
        return id
    }
    
    func deleteRecord(id recordId: Int64) -> Bool {
        deletedRecordIds.append(recordId)
        return true
    }
}

class MockDelayedNotificationsRepository: DelayedNotificationsRepositoryProtocol {
    var notifications: [DelayedNotification] = []
    var insertedNotifications: [DelayedNotification] = []
    var deletedNotificationIds: [Int64] = []
    var nextInsertId: Int64 = 1
    
    func getRecordByMaintenanceId(_ maintenanceRecordId: Int64) -> DelayedNotification? {
        return notifications.first { $0.maintenanceRecord == maintenanceRecordId }
    }
    
    func insertRecord(_ record: DelayedNotification) -> Int64? {
        insertedNotifications.append(record)
        let id = nextInsertId
        nextInsertId += 1
        return id
    }
    
    func deleteRecord(id recordId: Int64) -> Bool {
        deletedNotificationIds.append(recordId)
        return true
    }
}

class MockCarRepository: CarRepositoryProtocol {
    var selectedCar: Car?
    var getSelectedCarCallCount = 0
    
    func getSelectedForExpensesCar() -> Car? {
        getSelectedCarCallCount += 1
        return selectedCar
    }
}

class MockNotificationManager: NotificationManagerProtocol {
    var scheduledNotifications: [(title: String, body: String, date: Date)] = []
    var cancelledNotificationIds: [String] = []
    var nextNotificationId: String = "test-notification-id"
    
    func scheduleNotification(title: String, body: String, on date: Date) -> String {
        scheduledNotifications.append((title: title, body: body, date: date))
        return nextNotificationId
    }
    
    func cancelNotification(_ id: String) {
        cancelledNotificationIds.append(id)
    }
}

// MARK: - Helper Functions

func createTestCar(
    id: Int64 = 1,
    name: String = "Test Car",
    currentMileage: Int = 50000
) -> Car {
    return Car(
        id: id,
        name: name,
        selectedForTracking: true,
        batteryCapacity: 75.0,
        expenseCurrency: .usd,
        currentMileage: currentMileage,
        initialMileage: 0,
        milleageSyncedAt: Date(),
        createdAt: Date()
    )
}

func createTestMaintenance(
    id: Int64 = 1,
    name: String = "Oil Change",
    notes: String = "Test notes",
    when: Date? = nil,
    odometer: Int? = nil,
    carId: Int64 = 1
) -> PlannedMaintenance {
    return PlannedMaintenance(
        id: id,
        when: when,
        odometer: odometer,
        name: name,
        notes: notes,
        carId: carId,
        createdAt: Date()
    )
}

// MARK: - Tests

struct PlanedMaintenanceViewModelTests {

    // MARK: - loadData Tests
    
    @Test func loadData_whenNoSelectedCar_doesNotLoadRecords() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        mockCarRepo.selectedCar = nil
        mockMaintenanceRepo.records = [
            createTestMaintenance(id: 1, name: "Should not load", carId: 1)
        ]
        
        // Act
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: true
        )
        
        // Assert
        #expect(viewModel.maintenanceRecords.isEmpty)
    }
    
    @Test func loadData_whenSelectedCarExists_loadsRecordsForThatCar() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        let testCar = createTestCar(id: 1)
        mockCarRepo.selectedCar = testCar
        
        mockMaintenanceRepo.records = [
            createTestMaintenance(id: 1, name: "Brake Check", carId: 1),
            createTestMaintenance(id: 2, name: "Tire Rotation", carId: 1),
            createTestMaintenance(id: 3, name: "Other Car Maintenance", carId: 2)
        ]
        
        // Act
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        viewModel.loadData()
        
        // Wait for async dispatch
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert - should only load records for car 1
        #expect(viewModel.maintenanceRecords.count == 2)
        #expect(viewModel.maintenanceRecords.allSatisfy { $0.carId == 1 })
    }

    // MARK: - addNewMaintenanceRecord Tests
    
    @Test func addNewMaintenanceRecord_withoutDate_insertsRecordWithoutNotification() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        mockCarRepo.selectedCar = nil
        
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        
        let newRecord = createTestMaintenance(
            name: "New Maintenance",
            when: nil,
            odometer: 60000
        )
        
        // Act
        viewModel.addNewMaintenanceRecord(newRecord: newRecord)
        
        // Assert
        #expect(mockMaintenanceRepo.insertedRecords.count == 1)
        #expect(mockMaintenanceRepo.insertedRecords.first?.name == "New Maintenance")
        #expect(mockNotificationManager.scheduledNotifications.isEmpty)
        #expect(mockDelayedRepo.insertedNotifications.isEmpty)
    }
    
    @Test func addNewMaintenanceRecord_withDate_insertsRecordAndSchedulesNotification() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        mockCarRepo.selectedCar = nil
        
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let newRecord = createTestMaintenance(
            name: "Scheduled Maintenance",
            when: futureDate,
            carId: 1
        )
        
        // Act
        viewModel.addNewMaintenanceRecord(newRecord: newRecord)
        
        // Assert
        #expect(mockMaintenanceRepo.insertedRecords.count == 1)
        #expect(mockNotificationManager.scheduledNotifications.count == 1)
        #expect(mockNotificationManager.scheduledNotifications.first?.body == "Scheduled Maintenance")
        #expect(mockDelayedRepo.insertedNotifications.count == 1)
    }

    // MARK: - deleteMaintenanceRecord Tests
    
    @Test func deleteMaintenanceRecord_withoutDate_deletesRecordOnly() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        mockCarRepo.selectedCar = nil
        
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        
        let maintenance = createTestMaintenance(id: 1, when: nil)
        let recordToDelete = PlannedMaintenanceItem(maintenance: maintenance)
        
        // Act
        viewModel.deleteMaintenanceRecord(recordToDelete)
        
        // Assert
        #expect(mockMaintenanceRepo.deletedRecordIds.contains(1))
        #expect(mockNotificationManager.cancelledNotificationIds.isEmpty)
        #expect(mockDelayedRepo.deletedNotificationIds.isEmpty)
    }
    
    @Test func deleteMaintenanceRecord_withDateAndNotification_deletesRecordAndCancelsNotification() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        mockCarRepo.selectedCar = nil
        
        // Set up existing delayed notification
        let existingNotification = DelayedNotification(
            id: 10,
            when: Date(),
            notificationId: "notification-to-cancel",
            maintenanceRecord: 1,
            carId: 1,
            createdAt: Date()
        )
        mockDelayedRepo.notifications = [existingNotification]
        
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let maintenance = createTestMaintenance(id: 1, when: futureDate)
        let recordToDelete = PlannedMaintenanceItem(maintenance: maintenance)
        
        // Act
        viewModel.deleteMaintenanceRecord(recordToDelete)
        
        // Assert
        #expect(mockMaintenanceRepo.deletedRecordIds.contains(1))
        #expect(mockNotificationManager.cancelledNotificationIds.contains("notification-to-cancel"))
        #expect(mockDelayedRepo.deletedNotificationIds.contains(10))
    }
    
    @Test func deleteMaintenanceRecord_withDateButNoNotification_deletesRecordOnly() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        mockCarRepo.selectedCar = nil
        mockDelayedRepo.notifications = [] // No notifications exist
        
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let maintenance = createTestMaintenance(id: 1, when: futureDate)
        let recordToDelete = PlannedMaintenanceItem(maintenance: maintenance)
        
        // Act
        viewModel.deleteMaintenanceRecord(recordToDelete)
        
        // Assert
        #expect(mockMaintenanceRepo.deletedRecordIds.contains(1))
        #expect(mockNotificationManager.cancelledNotificationIds.isEmpty)
        #expect(mockDelayedRepo.deletedNotificationIds.isEmpty)
    }

    // MARK: - reloadSelectedCarForExpenses Tests
    
    @Test func reloadSelectedCarForExpenses_returnsCarFromRepository() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        let testCar = createTestCar(id: 5, name: "My Tesla")
        mockCarRepo.selectedCar = testCar
        
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        
        // Act
        let result = viewModel.reloadSelectedCarForExpenses()
        
        // Assert
        #expect(result != nil)
        #expect(result?.id == 5)
        #expect(result?.name == "My Tesla")
    }
    
    @Test func reloadSelectedCarForExpenses_whenNoCar_returnsNil() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        mockCarRepo.selectedCar = nil
        
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        
        // Act
        let result = viewModel.reloadSelectedCarForExpenses()
        
        // Assert
        #expect(result == nil)
    }

    // MARK: - selectedCarForExpenses Property Tests
    
    @Test func selectedCarForExpenses_whenNotCached_callsReload() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        let testCar = createTestCar(id: 3, name: "Cached Car")
        mockCarRepo.selectedCar = testCar
        
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        
        // Act
        let result = viewModel.selectedCarForExpenses
        
        // Assert
        #expect(result != nil)
        #expect(result?.id == 3)
        #expect(mockCarRepo.getSelectedCarCallCount >= 1)
    }
    
    @Test func selectedCarForExpenses_whenAlreadyCached_returnsCachedValue() async throws {
        // Arrange
        let mockMaintenanceRepo = MockPlannedMaintenanceRepository()
        let mockDelayedRepo = MockDelayedNotificationsRepository()
        let mockCarRepo = MockCarRepository()
        let mockNotificationManager = MockNotificationManager()
        
        let testCar = createTestCar(id: 7, name: "First Car")
        mockCarRepo.selectedCar = testCar
        
        let viewModel = PlanedMaintenanceViewModel(
            notificationsService: mockNotificationManager,
            maintenanceRepository: mockMaintenanceRepo,
            delayedNotificationsRepository: mockDelayedRepo,
            carRepository: mockCarRepo,
            loadDataOnInit: false
        )
        
        // First call to cache the value
        _ = viewModel.selectedCarForExpenses
        let initialCallCount = mockCarRepo.getSelectedCarCallCount
        
        // Change the car in the repository
        let newCar = createTestCar(id: 8, name: "Second Car")
        mockCarRepo.selectedCar = newCar
        
        // Act - Second call should use cached value
        let result = viewModel.selectedCarForExpenses
        
        // Assert - Should still return the first car (cached)
        #expect(result?.id == 7)
        #expect(result?.name == "First Car")
        // Call count should not increase significantly (property may call once to check nil)
        #expect(mockCarRepo.getSelectedCarCallCount == initialCallCount)
    }
}

// MARK: - PlannedMaintenanceItem Tests

struct PlannedMaintenanceItemTests {
    
    @Test func init_calculatesMileageDifference_whenCarAndOdometerProvided() async throws {
        // Arrange
        let car = createTestCar(currentMileage: 50000)
        let maintenance = createTestMaintenance(odometer: 55000)
        
        // Act
        let item = PlannedMaintenanceItem(maintenance: maintenance, car: car)
        
        // Assert
        #expect(item.mileageDifference == -5000) // 50000 - 55000
    }
    
    @Test func init_calculatesDaysDifference_whenDateProvided() async throws {
        // Arrange
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: now)!
        let maintenance = createTestMaintenance(when: futureDate)
        
        // Act
        let item = PlannedMaintenanceItem(maintenance: maintenance, now: now)
        
        // Assert
        #expect(item.daysDifference == 10)
    }
    
    @Test func compare_sortsByMileageDifferenceDescending_whenBothHaveMileage() async throws {
        // Arrange
        let car = createTestCar(currentMileage: 50000)
        let maintenance1 = createTestMaintenance(id: 1, odometer: 45000) // diff: 5000
        let maintenance2 = createTestMaintenance(id: 2, odometer: 48000) // diff: 2000
        
        let item1 = PlannedMaintenanceItem(maintenance: maintenance1, car: car)
        let item2 = PlannedMaintenanceItem(maintenance: maintenance2, car: car)
        
        // Act & Assert - item1 has higher mileage difference, should come first
        #expect(item1 < item2)
    }
    
    @Test func compare_sortsByDateAscending_whenBothHaveDates() async throws {
        // Arrange
        let now = Date()
        let earlierDate = Calendar.current.date(byAdding: .day, value: 5, to: now)!
        let laterDate = Calendar.current.date(byAdding: .day, value: 10, to: now)!
        
        let maintenance1 = createTestMaintenance(id: 1, when: earlierDate)
        let maintenance2 = createTestMaintenance(id: 2, when: laterDate)
        
        let item1 = PlannedMaintenanceItem(maintenance: maintenance1, now: now)
        let item2 = PlannedMaintenanceItem(maintenance: maintenance2, now: now)
        
        // Act & Assert - earlier date should come first
        #expect(item1 < item2)
    }
    
    @Test func equality_returnsTrue_whenSameDateAndMileageDifference() async throws {
        // Arrange
        let car = createTestCar(currentMileage: 50000)
        let date = Date()
        let maintenance1 = createTestMaintenance(id: 1, when: date, odometer: 45000)
        let maintenance2 = createTestMaintenance(id: 2, when: date, odometer: 45000)
        
        let item1 = PlannedMaintenanceItem(maintenance: maintenance1, car: car)
        let item2 = PlannedMaintenanceItem(maintenance: maintenance2, car: car)
        
        // Act & Assert
        #expect(item1 == item2)
    }
}
