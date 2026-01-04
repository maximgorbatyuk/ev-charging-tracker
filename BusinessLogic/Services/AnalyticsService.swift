//
//  AnalyticsService.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 07.11.2025.
//

import Foundation
import FirebaseAnalytics
import os

class AnalyticsService: ObservableObject {

    static let shared = AnalyticsService()

    private var _globalProps: [String: Any]? = nil
    private var _sessionId = UUID().uuidString
    private var _userId: String?

    let environment: EnvironmentService
    let db: DatabaseManager
    let logger: Logger

    init() {
        self.environment = EnvironmentService.shared
        self.db = DatabaseManager.shared
        self.logger = Logger(subsystem: "AnalyticsService", category: "Analytics")
        
        // Initialize user_id from database
        self.initializeUserId()
    }

    private func initializeUserId() {
        if let userSettingsRepo = db.userSettingsRepository {
            self._userId = userSettingsRepo.fetchOrGenerateUserId()
            logger.info("Initialized user_id: \(self._userId ?? "nil")")
        }
    }

    func trackEvent(_ name: String, properties: [String: Any]? = nil) -> Void {
        let mergedParams = mergeProperties(properties)
        if (environment.isDevelopmentMode()) {
            logger.info("Analytics Event: \(name), properties: \(String(describing: mergedParams))")
        }

        Analytics.logEvent(name, parameters: mergedParams)
    }

    func identifyUser(_ userId: String, properties: [String: Any]? = nil) -> Void {
        if (environment.isDevelopmentMode()) {
            logger.info("Analytics Identify User: \(userId), properties: \(String(describing: properties))")
        }

        Analytics.setUserID(userId)
        properties?.forEach { key, value in
            Analytics.setUserProperty(String(describing: value), forName: key)
        }
    }

    func trackScreen(_ screenName: String, properties: [String: Any]? = nil) -> Void {
        var mergedParams = mergeProperties(properties)
        mergedParams[AnalyticsParameterScreenName] = screenName
        mergedParams[AnalyticsParameterScreenClass] = screenName

        if (environment.isDevelopmentMode()) {
            logger.info("Analytics Screen View: \(screenName), properties: \(String(describing: mergedParams))")
        }

        Analytics.logEvent(AnalyticsEventScreenView, parameters: mergedParams)
    }

    func trackButtonTap(_ buttonName: String, screen: String, additionalParams: [String: Any]? = nil) {
        var params: [String: Any] = [
            "button_name": buttonName,
            "screen": screen
        ]

        params.merge(additionalParams ?? [:]) { _, new in new }

        trackEvent("button_tapped", properties: params)
    }

    private func mergeProperties(_ parameters: [String: Any]?) -> [String: Any] {
        var merged = getGlobalProperties()

        if let params = parameters {
            merged.merge(params) { current, new in new } // new value takes precedence
        }

        return merged
    }

    private func getGlobalProperties() -> [String: Any] {
        if (_globalProps != nil) {
            return _globalProps!
        }

        _globalProps = [
            "session_id": _sessionId,
            "app_version": environment.getAppVisibleVersion(),
            "environment": environment.getBuildEnvironment(),
            "platform": "iOS",
            "os_version": environment.getOsVersion(),
            "app_language": environment.getAppLanguage()
        ]

        // Add user_id if available
        if let userId = _userId {
            _globalProps!["user_id"] = userId
        }

        return _globalProps!
    }
}
