//
//  ConsumptionBasisManager.swift
//  EVChargingTracker
//

import Combine
import Foundation

/// Holds the app-wide preference for whether the energy-consumption figure on
/// the Stats screen is shown per a hundred units (kWh / 100km) or per a single
/// unit (kWh / 1km). Kept separate from `DistanceCostBasisManager` so toggling
/// the energy card does not affect the per-distance cost cards.
final class ConsumptionBasisManager: ObservableObject {
    static let shared = ConsumptionBasisManager()

    private static let consumptionBasisKey = "consumption_basis"

    @Published var currentBasis: DistanceCostBasis

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.consumptionBasisKey),
           let basis = DistanceCostBasis(rawValue: stored) {
            self.currentBasis = basis
        } else {
            self.currentBasis = .perHundredUnits
        }
    }

    /// Updates the basis and persists it to UserDefaults.
    func setBasis(_ basis: DistanceCostBasis) {
        guard basis != currentBasis else {
            return
        }

        currentBasis = basis
        UserDefaults.standard.set(basis.rawValue, forKey: Self.consumptionBasisKey)
    }
}
