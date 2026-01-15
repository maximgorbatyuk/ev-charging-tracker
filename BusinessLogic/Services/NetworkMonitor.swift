//
//  NetworkMonitor.swift
//  EVChargingTracker
//
//  Service for monitoring network connectivity
//

import Foundation
import Network
import os

enum NetworkError: LocalizedError {
    case noConnection

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return String(localized: "backup.error.network_unavailable")
        }
    }
}

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.evchargingtracker.networkmonitor")
    private let logger = Logger(subsystem: "com.evchargingtracker.businesslogic", category: "NetworkMonitor")

    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown

        var description: String {
            switch self {
            case .wifi: return "WiFi"
            case .cellular: return "Cellular"
            case .wiredEthernet: return "Wired"
            case .unknown: return "Unknown"
            }
        }
    }

    private init() {
        self.monitor = NWPathMonitor()
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                let wasConnected = self.isConnected
                self.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wiredEthernet
                } else {
                    self.connectionType = .unknown
                }

                if wasConnected != self.isConnected {
                    self.logger.info("Network status changed: connected=\(self.isConnected), type=\(self.connectionType.description)")
                }
            }
        }

        monitor.start(queue: queue)
        logger.info("Network monitoring started")
    }

    deinit {
        monitor.cancel()
    }

    /// Synchronously check if network is available
    /// Use this for quick checks before initiating network operations
    func checkConnectivity() -> Bool {
        return isConnected
    }

    /// Check if network is available and throw an error if not
    func requireNetwork() throws {
        guard isConnected else {
            throw NetworkError.noConnection
        }
    }
}
