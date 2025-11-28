//
//  PlannedMaintenanceItemTests.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 28.11.2025.
//

import Testing
@testable import EVChargingTracker

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
