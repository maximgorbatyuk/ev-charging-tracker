//
//  MeasurementSystem.swift
//  EVChargingTracker
//
//  Per-car distance/weight unit. Toggling between systems does NOT
//  recompute stored mileage values — only display labels and the CO₂
//  block on the Stats screen react. CO₂ is converted kg → lb at the
//  display boundary (Option B), keeping the underlying formula
//  `co2PerKm * totalDistance` unchanged.
//

import Foundation

enum MeasurementSystem: String, Codable, CaseIterable {
    case metric
    case imperial

    var distanceUnitLabel: String {
        switch self {
        case .metric: return L("km")
        case .imperial: return L("mi")
        }
    }

    var co2UnitLabel: String {
        switch self {
        case .metric: return L("kg")
        case .imperial: return L("lb")
        }
    }
}

/// 1 lb = 0.453592 kg. Used to convert CO₂ saved on the Stats block
/// when the selected car's measurement system is `.imperial`.
let kilogramsPerPound: Double = 0.453592
