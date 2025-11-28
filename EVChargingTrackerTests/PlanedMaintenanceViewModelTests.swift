//
//  EVChargingTrackerTests.swift
//  EVChargingTrackerTests
//
//  Created by Maxim Gorbatyuk on 08.10.2025.
//

import Testing
@testable import EVChargingTracker

// MARK: - Tests

struct PlanedMaintenanceViewModelTests {
    
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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))
        
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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))

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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))

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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))

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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))

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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))
        
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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))
        
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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))
        
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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))
        
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
            notifications: mockNotificationManager,
            db: DatabaseManagerFake(
                plannedMaintenanceRepository: mockMaintenanceRepo,
                delayedNotificationsRepository: mockDelayedRepo,
                carRepository: mockCarRepo
            ))
        
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
