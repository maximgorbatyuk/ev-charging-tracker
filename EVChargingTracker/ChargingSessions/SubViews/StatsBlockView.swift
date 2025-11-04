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
                title: "kWh / 100km",
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

struct StatCard: SwiftUICore.View {

    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let value: String
    let icon: String
    let color: Color
    let minHeight: CGFloat

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.9))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
