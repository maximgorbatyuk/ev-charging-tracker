//
//  NotificationManagerProtocol.swift
//  EVChargingTracker
//
//  Created for unit testing support
//

import Foundation

protocol NotificationManagerProtocol {
    func scheduleNotification(title: String, body: String, on date: Date) -> String
    func cancelNotification(_ id: String)
}

extension NotificationManager: NotificationManagerProtocol {}
