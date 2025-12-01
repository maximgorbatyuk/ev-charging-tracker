import Foundation
import UIKit

protocol AppVersionCheckerProtocol {
    func checkAppStoreVersion() async -> Bool?
}

class AppVersionChecker : AppVersionCheckerProtocol {
   
    private let environment: EnvironmentService

    init(
        environment: EnvironmentService
    ) {
        self.environment = environment
    }

    func checkAppStoreVersion() async -> Bool? {
        let currentVersionWithBuild = environment.getAppVisibleVersion()
        let splitBySpace = currentVersionWithBuild.split(separator: " ")
        let currentVersion = splitBySpace.first ?? ""

        guard
            let appStoreId = environment.getAppStoreId(),
            let url = URL(string: "https://itunes.apple.com/lookup?id=\(appStoreId)") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            print("Version check response: \(json)")

            let results = json?["results"] as? [[String: Any]]

            let appStoreVersion = results?.first?["version"] as? String ?? "-"

            if (appStoreVersion == "-") {
                print("No version info found in App Store response")
                return nil
            }

            return currentVersion != appStoreVersion
        } catch {
            print("Version check failed: \(error)")
            return nil
        }
    }
}
