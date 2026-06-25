//
//  FuelCalc.swift
//  EVChargingTracker
//
//  Pure arithmetic for the fuel three-way auto-calc. Kept free of view/state so
//  the math (cost = volume × price; volume = cost / price) is unit-testable.
//

import Foundation

enum FuelCalc {
    static func cost(volume: Double, price: Double) -> Double {
        return volume * price
    }

    /// Volume from cost and price. Returns nil when price is non-positive to
    /// avoid division by zero.
    static func volume(cost: Double, price: Double) -> Double? {
        guard price > 0 else {
            return nil
        }

        return cost / price
    }
}
