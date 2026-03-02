//
//  EnvironmentService.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

import Foundation
import UIKit

class EnvironmentService: ObservableObject {

    var _developerName: String?
    var _gitHubRepositoryUrl: String?
    var _buildEnvironment: String?
    var _appVisibleVersion: String?
    var _developerTelegramLink: String?
    var _appStoreAppLink: String?
    var _co2EuropePollutionPerOneKilometer: Double?
    var _appBundleId: String?
    var _appGroupIdentifier: String?

    static let shared = EnvironmentService()

    func getAppVisibleVersion() -> String {

        if _appVisibleVersion != nil {
            return _appVisibleVersion!
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        self._appVisibleVersion = "\(version) (\(build))"

        return _appVisibleVersion!
    }

    func getAppStoreId() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "AppStoreId") as? String
    }

    func getAppBundleId() -> String? {
        if _appBundleId != nil {
            return _appBundleId!
        }

        _appBundleId = Bundle.main.bundleIdentifier
        return _appBundleId
    }

    func getDeveloperName() -> String {
        if _developerName != nil {
            return _developerName!
        }

        _developerName = Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String ?? "-"
        return _developerName!
    }

    func getGitHubRepositoryUrl() -> String {
        if _gitHubRepositoryUrl != nil {
            return _gitHubRepositoryUrl!
        }

        _gitHubRepositoryUrl = Bundle.main.object(forInfoDictionaryKey: "GithubRepoUrl") as? String ?? "-"
        return _gitHubRepositoryUrl!
    }

    func getBuildEnvironment() -> String {
        if _buildEnvironment != nil {
            return _buildEnvironment!
        }

        _buildEnvironment = Bundle.main.object(forInfoDictionaryKey: "BuildEnvironment") as? String ?? "-"
        return _buildEnvironment!
    }

    func getDeveloperTelegramLink() -> String {
        if _developerTelegramLink != nil {
            return _developerTelegramLink!
        }

        _developerTelegramLink = Bundle.main.object(forInfoDictionaryKey: "DeveloperTelegramLink") as? String ?? "-"
        if _developerTelegramLink != "-" {
            _developerTelegramLink = "https://\(_developerTelegramLink!)"
        }

        return _developerTelegramLink!
    }

    func getAppStoreAppLink() -> String {
        if let cached = _appStoreAppLink {
            return cached
        }

        let appStoreId = self.getAppStoreId() ?? ""
        _appStoreAppLink = "https://apps.apple.com/app/id\(appStoreId)"
        return _appStoreAppLink!
    }

    func getCo2EuropePollutionPerOneKilometer() -> Double {
        if _co2EuropePollutionPerOneKilometer != nil {
            return _co2EuropePollutionPerOneKilometer!
        }

        let valueAsString = Bundle.main.object(forInfoDictionaryKey: "Co2EuropePollutionPerOneKilometer") as? String ?? "0.0"
        _co2EuropePollutionPerOneKilometer = Double(valueAsString) ?? 0.0

        return _co2EuropePollutionPerOneKilometer!
    }

    func getAppGroupIdentifier() -> String? {
        if let _appGroupIdentifier {
            return _appGroupIdentifier
        }

        let value = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
        _appGroupIdentifier = value
        return value
    }

    func isDevelopmentMode() -> Bool {
        return self.getBuildEnvironment() == "dev"
    }

    func getOsVersion() -> String {
        return UIDevice.current.systemVersion
    }

    func getAppLanguage() -> String {
        Locale.current.language.languageCode?.identifier ?? "unknown"
    }
}
