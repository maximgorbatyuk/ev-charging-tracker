import Foundation
import UIKit

protocol AppVersionCheckerProtocol {
    func openLinkToUpdate()
    func checkAppStoreVersion(_ completion: @escaping (Bool?) -> Void) async -> Void
}

class AppVersionChecker : AppVersionCheckerProtocol {
   
    private let environment: EnvironmentService

    init(
        environment: EnvironmentService
    ) {
        self.environment = environment
    }

    func openLinkToUpdate() {
        guard let bundleId = environment.getAppBundleId() else { return }
        if let url = URL(string: "itms-apps://apple.com/app/id\(bundleId)") {
            UIApplication.shared.open(url)
        }
    }

    func checkAppStoreVersion(_ completion: @escaping (Bool?) -> Void) async -> Void {
        let currentVersion = environment.getAppVisibleVersion()
        guard let bundleId = environment.getAppBundleId(),
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            completion(nil)
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            print("Version check response: \(json)")

            let results = json?["results"] as? [[String: Any]]

            let currentVersion = environment.getAppVisibleVersion()
            let appStoreVersion = results?.first?["version"] as? String?

            if (appStoreVersion == nil) {
                print("No version info found in App Store response")
                completion(nil)
            }

            completion(appStoreVersion != currentVersion)
        } catch {
            print("Version check failed: \(error)")
            completion(nil)
        }
    }
}
