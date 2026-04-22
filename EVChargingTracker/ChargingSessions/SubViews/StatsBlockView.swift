//
//  StatsBlockView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 17.10.2025.
//

import SwiftUI

struct StatsBlockView: SwiftUICore.View {

    let co2Saved: Double
    let averageEnergy: Double
    let chargingSessionsCount: Int

    var body: some SwiftUICore.View {
        HStack(alignment: .top, spacing: 10) {
            StatCard(
                title: L("CO₂ saved (kg)"),
                value: String(format: "%.1f", co2Saved)
            )

            StatCard(
                title: L("kWh / 100km"),
                value: String(format: "%.1f", averageEnergy)
            )

            StatCard(
                title: L("Charges"),
                value: "\(chargingSessionsCount)"
            )
        }
    }
}

struct StatCard: SwiftUICore.View {

    let title: String
    let value: String

    var body: some SwiftUICore.View {
        AppCard(pad: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .textCase(.uppercase)
                    .appFont(.caption2, weight: .semibold)
                    .tracking(0.3)
                    .foregroundColor(AppColors.inkSoft)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.8)

                Text(value)
                    .font(AppFont.mono(size: 22, weight: .bold, relativeTo: .title2))
                    .tracking(-0.8)
                    .foregroundColor(AppColors.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
    }
}
