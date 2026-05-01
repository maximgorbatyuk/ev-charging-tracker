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
    /// Drives the CO₂ unit (kg ↔ lb) and the consumption denominator
    /// label (100km ↔ 100mi). The numeric `co2Saved` and `averageEnergy`
    /// values are produced by `ChargingViewModel`, which already applies
    /// the kg → lb conversion when the selected car is `.imperial`.
    var measurementSystem: MeasurementSystem = .metric

    var body: some SwiftUICore.View {
        HStack(alignment: .top, spacing: 10) {
            StatCard(
                title: String(format: L("CO₂ saved (%@)"), measurementSystem.co2UnitLabel),
                value: String(format: "%.1f", co2Saved),
                style: .co2Saved
            )

            StatCard(
                title: measurementSystem == .imperial
                    ? L("kWh / 100mi")
                    : L("kWh / 100km"),
                value: String(format: "%.1f", averageEnergy),
                style: .energy
            )

            StatCard(
                title: L("Charges"),
                value: "\(chargingSessionsCount)",
                style: .charges
            )
        }
    }
}

enum StatCardTint: Equatable {
    case greenLeaf
    case blue
    case yellow

    var color: Color {
        switch self {
        case .greenLeaf:
            return AppColors.greenLeaf

        case .blue:
            return AppColors.blue

        case .yellow:
            return AppColors.yellow
        }
    }
}

enum StatCardStyle: Equatable {
    case co2Saved
    case energy
    case charges

    var iconName: String {
        switch self {
        case .co2Saved:
            return "leaf.fill"

        case .energy:
            return "steeringwheel"

        case .charges:
            return "bolt.fill"
        }
    }

    var tint: StatCardTint {
        switch self {
        case .co2Saved:
            return .greenLeaf

        case .energy:
            return .blue

        case .charges:
            return .yellow
        }
    }
}

struct StatCard: SwiftUICore.View {

    let title: String
    let value: String
    let style: StatCardStyle

    var body: some SwiftUICore.View {
        AppCard(pad: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: style.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(style.tint.color)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(style.tint.color.opacity(0.16))
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .textCase(.uppercase)
                        .appFont(.caption2, weight: .semibold)
                        .tracking(0.3)
                        .foregroundColor(AppColors.inkSoft)
                        .lineLimit(2, reservesSpace: true)
                        .minimumScaleFactor(0.8)

                    Text(value)
                        .appFont(.title2, weight: .bold)
                        .monospacedDigit()
                        .tracking(-0.8)
                        .foregroundColor(AppColors.ink)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
        }
    }
}
