//
//  StatsBlockViewTests.swift
//  EVChargingTrackerTests
//
//  Verifies stat card icon mapping for the car stats screen.
//

import Testing
@testable import EVChargingTracker

struct StatsBlockViewTests {

    @Test func statCardStyles_useRequestedIconsAndTints() {
        #expect(StatCardStyle.co2Saved.iconName == "leaf.fill")
        #expect(StatCardStyle.co2Saved.tint == .greenLeaf)
        #expect(StatCardStyle.energy.iconName == "steeringwheel")
        #expect(StatCardStyle.energy.tint == .blue)
        #expect(StatCardStyle.charges.iconName == "bolt.fill")
        #expect(StatCardStyle.charges.tint == .yellow)
    }
}
