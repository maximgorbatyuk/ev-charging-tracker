//
//  DistanceCostBasisManager.swift
//  EVChargingTracker
//

import Combine
import Foundation

/// Holds the app-wide preference for whether per-distance cost figures on the
/// Stats screen are shown per a single unit or per a hundred units. Persists to
/// UserDefaults and publishes changes so the Stats screen reacts immediately.
final class DistanceCostBasisManager: ObservableObject {
    static let shared = DistanceCostBasisManager()

    private static let distanceCostBasisKey = "distance_cost_basis"

    @Published var currentBasis: DistanceCostBasis

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.distanceCostBasisKey),
           let basis = DistanceCostBasis(rawValue: stored) {
            self.currentBasis = basis
        } else {
            self.currentBasis = .perUnit
        }
    }

    /// Updates the basis and persists it to UserDefaults.
    func setBasis(_ basis: DistanceCostBasis) {
        guard basis != currentBasis else {
            return
        }

        currentBasis = basis
        UserDefaults.standard.set(basis.rawValue, forKey: Self.distanceCostBasisKey)
    }
}
