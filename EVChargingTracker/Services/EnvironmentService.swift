//
//  EnvironmentService.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

import Foundation

class EnvironmentService: ObservableObject {

    var _developerName: String? = nil
    var _gitHubRepositoryUrl: String? = nil
    var _buildEnvironment: String? = nil
    var _appVisibleVersion: String? = nil
    var _developerTelegramLink: String? = nil
    var _appStoreAppLink : String? = nil

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
        if _appStoreAppLink != nil {
            return _appStoreAppLink!
        }

        _appStoreAppLink = Bundle.main.object(forInfoDictionaryKey: "AppStoreAppLink") as? String ?? "-"
        if _appStoreAppLink != "-" {
            _appStoreAppLink = "https://\(_appStoreAppLink!)"
        }

        return _appStoreAppLink!
    }

    func isDevelopmentMode() -> Bool {
        return self.getBuildEnvironment() == "dev"
    }
}
