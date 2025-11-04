//
//  NotificationManager.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 02.11.2025.
//

import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

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
                print("Permission granted")
            } else if let error = error {
                print("Error: \(error.localizedDescription)")
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

    func sendNotification(title: String, body: String) -> Void {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        sendNotification(
            title: title,
            body: body,
            trigger: trigger)
    }

    func scheduleNotification(title: String, body: String, afterSeconds: Int32) -> Void {
        let seconds = TimeInterval(afterSeconds)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false)

        sendNotification(
            title: title,
            body: body,
            trigger: trigger)
    }

    func scheduleNotification(title: String, body: String, on date: Date) -> Void {
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        sendNotification(
            title: title,
            body: body,
            trigger: trigger)
    }

    func getPendingNotificationRequests() -> Void {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("Pending notifications: \(requests.count)")
            for request in requests {
                print("Pending notification: \(request.identifier) - \(request.content.title)")
            }
        }
    }

    private func sendNotification(
        title: String,
        body: String,
        trigger: UNNotificationTrigger
    ) -> Void {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}
