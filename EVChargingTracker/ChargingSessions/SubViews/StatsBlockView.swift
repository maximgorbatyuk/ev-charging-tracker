//
//  StatsBlockView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 17.10.2025.
//

import SwiftUI

struct StatsBlockView: SwiftUICore.View {
    
    let totalEnergy: Double
    let averageEnergy: Double
    let chargingSessionsCount: Int

    var body: some SwiftUICore.View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total (kWh)",
                value: String(format: "%.1f", totalEnergy),
                icon: "bolt.fill",
                color: .yellow,
                minHeight: 90
            )
            
            StatCard(
                title: "Avg (kWh)",
                value: String(format: "%.1f ", averageEnergy),
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                minHeight: 90
            )
            
            StatCard(
                title: "Charges",
                value: "\(chargingSessionsCount)",
                icon: "gauge.high",
                color: .blue,
                minHeight: 90
            )
        }
    }
}
