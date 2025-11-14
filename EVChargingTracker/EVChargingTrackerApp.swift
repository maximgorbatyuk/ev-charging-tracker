//
//  EVChargingTrackerApp.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 08.10.2025.
//

import SwiftUI
import UserNotifications
import FirebaseCore

@main
struct EVChargingTrackerApp: App {

    // For allowing notifications in foreground
    @UIApplicationDelegateAdaptor(ForegroundNotificationDelegate.self) var appDelegate

    private var analytics = AnalyticsService.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    analytics.trackEvent("app_opened")
                }
        }
    }
}

// For allowing notifications in foreground
final class ForegroundNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  static let shared = ForegroundNotificationDelegate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set the delegate
        UNUserNotificationCenter.current().delegate = self
        
        #if DEBUG
        #else
        FirebaseApp.configure()
        #endif

        return true
    }

    // Show alert while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void) {
        completion([.banner, .list, .sound])
    }
    
    // Handle taps / actions
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completion: @escaping () -> Void) {
        // route user based on response.actionIdentifier or notification.request.content.userInfo
        completion()
    }
}
