import Foundation
import UIKit
import os

protocol AppVersionCheckerProtocol {
    func checkAppStoreVersion() async -> Bool?
}

class AppVersionChecker : AppVersionCheckerProtocol {
   
    private let environment: EnvironmentService
    private let logger: Logger

    init(
        environment: EnvironmentService,
        logger: Logger? = nil
    ) {
        self.environment = environment
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "AppVersionChecker")
    }

    func checkAppStoreVersion() async -> Bool? {
        let currentVersionWithBuild = environment.getAppVisibleVersion()
        let splitBySpace = currentVersionWithBuild.split(separator: " ")
        let currentVersion = splitBySpace.first ?? ""

        let today = Date()
        let currentWeekOfYear = Calendar.current.component(.weekOfYear, from: today)
        let currentYear = Calendar.current.component(.year, from: today)
        let dayOfWeek = Calendar.current.component(.weekday, from: today)

        let queryParam = "\(currentYear).\(currentWeekOfYear).\(dayOfWeek)"

        guard
            let appStoreId = environment.getAppStoreId(),
            let url = URL(string: "https://itunes.apple.com/lookup?id=\(appStoreId)&current=\(currentVersion)&now=\(queryParam)") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            logger.debug("Version check response: \(String(describing: json))")

            let results = json?["results"] as? [[String: Any]]

            let appStoreVersion = results?.first?["version"] as? String ?? "-"

            if (appStoreVersion == "-") {
                logger.info("No version info found in App Store response")
                return nil
            }

            return currentVersion != appStoreVersion
        } catch {
            logger.error("Version check failed: \(error)")
            return nil
        }
    }
}
