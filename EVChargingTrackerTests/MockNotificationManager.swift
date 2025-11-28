//
//  MockNotificationManager.swift
//  EVChargingTrackerTests
//
//  Mock implementation of NotificationManagerProtocol for testing
//

import Foundation
@testable import EVChargingTracker

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
