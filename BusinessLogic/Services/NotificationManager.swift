//
//  NotificationManager.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 02.11.2025.
//

import UserNotifications
import Foundation
import os

protocol NotificationManagerProtocol {
    func scheduleNotification(title: String, body: String, on date: Date) -> String
    func cancelNotification(_ id: String)
}

class NotificationManager: ObservableObject, NotificationManagerProtocol {
    static let shared = NotificationManager()
    
    private let logger: Logger
    
    init(logger: Logger? = nil) {
        self.logger = Logger(subsystem: "NotificationManager", category: "Notifications")
    }

    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) -> Void {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                // First time - request permission
                self.requestPermission()
            }
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, error in
            if granted {
                self.logger.info("Permission granted")
            } else if let error = error {
                self.logger.error("Error: \(error.localizedDescription)")
            }
        }
    }

    func checkAndRequestPermission(
        completion: @escaping () -> Void,
        onDeniedNotificationPermission: @escaping () -> Void) -> Void {

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // Request permission
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    if granted {
                        completion()
                    } else {
                        DispatchQueue.main.async {
                            onDeniedNotificationPermission()
                        }
                    }
                }

            case .authorized:
                completion()

            case .denied:
                DispatchQueue.main.async {
                    onDeniedNotificationPermission()
                }

            default:
                break
            }
        }
    }

    func cancelNotification(_ id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func sendNotification(title: String, body: String) -> String {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        return sendNotification(
            title: title,
            body: body,
            trigger: trigger)
    }

    func scheduleNotification(title: String, body: String, afterSeconds: Int32) -> String {
        let seconds = TimeInterval(afterSeconds)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false)

        return sendNotification(
            title: title,
            body: body,
            trigger: trigger)
    }

    func scheduleNotification(title: String, body: String, on date: Date) -> String {
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        return sendNotification(
            title: title,
            body: body,
            trigger: trigger)
    }

    func getPendingNotificationRequests() -> Void {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            self.logger.info("Pending notifications: \(requests.count)")
            for request in requests {
                self.logger.info("Pending notification: \(request.identifier) - \(request.content.title)")
            }
        }
    }

    private func sendNotification(
        title: String,
        body: String,
        trigger: UNNotificationTrigger
    ) -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Error: \(error.localizedDescription)")
            }
        }

        return identifier
    }
}
