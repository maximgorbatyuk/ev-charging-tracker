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

    @ObservedObject private var consumptionBasisManager = ConsumptionBasisManager.shared
    @ObservedObject private var analytics = AnalyticsService.shared
    @State private var showingConsumptionInfo = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Consumption label, varying by unit and the selected per-1/per-100 basis.
    private var energyTitle: String {
        switch (measurementSystem, consumptionBasisManager.currentBasis) {
        case (.imperial, .perHundredUnits): return L("kWh / 100mi")
        case (.imperial, .perUnit): return L("kWh / mi")
        case (.metric, .perHundredUnits): return L("kWh / 100km")
        case (.metric, .perUnit): return L("kWh / km")
        }
    }

    /// `averageEnergy` is stored per 100 units; the per-1 view divides at the display boundary.
    private var energyValue: String {
        switch consumptionBasisManager.currentBasis {
        case .perHundredUnits: return String(format: "%.1f", averageEnergy)
        case .perUnit: return String(format: "%.2f", averageEnergy / 100.0)
        }
    }

    var body: some SwiftUICore.View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 10))

        layout {
            StatCard(
                title: String(format: L("CO₂ saved (%@)"), measurementSystem.co2UnitLabel),
                value: String(format: "%.1f", co2Saved),
                style: .co2Saved
            )

            Button(action: {
                analytics.trackEvent(
                    "consumption_basis_card_clicked",
                    properties: ["screen": "charging_sessions_stats_screen"]
                )
                showingConsumptionInfo = true
            }) {
                StatCard(
                    title: energyTitle,
                    value: energyValue,
                    style: .energy,
                    showsInfoIndicator: true
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingConsumptionInfo) {
                ConsumptionHintModalView(
                    hint: L("Average energy your car consumes over a distance. Switch between per 100 km/mi and per 1 km/mi.")
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }

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
    /// Shows a small info glyph to signal the card is tappable.
    var showsInfoIndicator: Bool = false

    var body: some SwiftUICore.View {
        AppCard(pad: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 0) {
                    Image(systemName: style.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(style.tint.color)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(style.tint.color.opacity(0.16))
                        )
                        .accessibilityHidden(true)

                    if showsInfoIndicator {
                        Spacer(minLength: 0)
                        Image(systemName: "info.circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.inkSoft)
                            .accessibilityHidden(true)
                    }
                }

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
