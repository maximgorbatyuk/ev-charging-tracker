//
//  SessionCard.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 11.10.2025.
//
//  Circuit row card per design.md §6.1 / §3.5.
//

import Foundation
import SwiftUI

struct SessionCard: SwiftUICore.View {

    let session: Expense
    /// Unit applied to the odometer label. The session's underlying
    /// integer is shown as-is — no value conversion happens here.
    let measurementSystem: MeasurementSystem

    var body: some SwiftUICore.View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                headerRow
                metaRow

                if showsNotesBlock {
                    Text(session.notes)
                        .appFont(.caption)
                        .foregroundColor(AppColors.inkFaint)
                        .lineLimit(2)
                }
            }
        }
    }

    // MARK: - Sections

    private var headerRow: some SwiftUICore.View {
        HStack(alignment: .top, spacing: 12) {
            iconTile

            VStack(alignment: .leading, spacing: 4) {
                if showsEyebrow {
                    Text(eyebrowText)
                        .textCase(.uppercase)
                        .appFont(.caption2, weight: .semibold)
                        .tracking(0.3)
                        .foregroundColor(AppColors.inkSoft)
                }

                titleView
            }

            Spacer(minLength: 8)

            if let cost = session.cost {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%@%.2f", session.currency.rawValue, cost))
                        .appFont(.headline, weight: .semibold)
                        .monospacedDigit()
                        .foregroundColor(AppColors.green)

                    if let subRate = subRateText(for: cost) {
                        Text(subRate)
                            .appFont(.caption2)
                            .monospacedDigit()
                            .foregroundColor(AppColors.inkSoft)
                    }
                }
            }
        }
    }

    private var metaRow: some SwiftUICore.View {
        HStack(spacing: 16) {
            Label(
                session.date.formatted(as: "yyyy-MM-dd"),
                systemImage: "calendar"
            )
            .appFont(.subheadline)
            .monospacedDigit()
            .foregroundColor(AppColors.inkSoft)

            Label(
                "\(session.odometer.formatted()) \(measurementSystem.distanceUnitLabel)",
                systemImage: "speedometer"
            )
            .appFont(.subheadline)
            .monospacedDigit()
            .foregroundColor(AppColors.inkSoft)

            Spacer()
        }
    }

    // MARK: - Icon tile

    private var iconTile: some SwiftUICore.View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(iconTileFill)
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: iconName)
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundColor(iconTint)
            )
    }

    private var iconName: String {
        switch session.expenseType {
        case .charging: return "bolt.fill"
        case .fuel: return "fuelpump.fill"
        case .maintenance: return "wrench.fill"
        case .repair: return "wrench.and.screwdriver.fill"
        case .carwash: return "drop.fill"
        case .other: return "creditcard.fill"
        }
    }

    private var iconTint: Color {
        switch session.expenseType {
        case .charging: return AppColors.green
        case .fuel: return AppColors.purple
        case .maintenance: return AppColors.orange
        case .repair: return AppColors.red
        case .carwash: return AppColors.teal
        case .other: return AppColors.inkSoft
        }
    }

    private var iconTileFill: Color {
        switch session.expenseType {
        case .charging: return AppColors.greenSoft
        case .fuel: return AppColors.purpleSoft
        case .maintenance: return AppColors.orangeSoft
        case .repair: return AppColors.redSoft
        case .carwash: return AppColors.tealSoft
        case .other: return AppColors.surfaceAlt
        }
    }

    // MARK: - Title

    @ViewBuilder
    private var titleView: some SwiftUICore.View {
        // Mono digits help "35.2 kWh" stay tabular; for non-charging the title
        // is free-form notes text where mono advances would just look off.
        Group {
            if session.expenseType == .charging || session.expenseType == .fuel {
                Text(titleText).monospacedDigit()
            } else {
                Text(titleText)
            }
        }
        .appFont(.headline, weight: .semibold)
        .foregroundColor(AppColors.ink)
        .lineLimit(2)
        .truncationMode(.tail)
    }

    private var titleText: String {
        switch session.expenseType {
        case .charging:
            return String(format: L("%.1f kWh"), session.energyCharged)
        case .fuel:
            return String(format: L("%.1f %@"), session.fuelVolume ?? 0, measurementSystem.volumeUnitLabel)
        default:
            return session.notes.isEmpty
                ? session.expenseType.localizedName
                : session.notes
        }
    }

    private var showsEyebrow: Bool {
        // For non-charging rows with no notes, the title already carries the
        // type label — skip the eyebrow to avoid the same word appearing twice.
        if session.expenseType == .charging || session.expenseType == .fuel { return true }
        return !session.notes.isEmpty
    }

    private var showsNotesBlock: Bool {
        // Non-charging rows promote notes into the title, so a separate block
        // would duplicate. Charging and fuel rows still get a notes line below.
        guard !session.notes.isEmpty else { return false }
        return session.expenseType == .charging || session.expenseType == .fuel
    }

    /// Eyebrow label. Fuel rows append the octane grade (e.g. "FUEL · 95 RON")
    /// since the title shows volume rather than the grade.
    private var eyebrowText: String {
        if session.expenseType == .fuel,
           let fuelType = session.fuelType {
            return "\(session.expenseType.localizedName) · \(fuelType.localizedName)"
        }

        return session.expenseType.localizedName
    }

    private func subRateText(for cost: Double) -> String? {
        if session.expenseType == .charging,
           session.energyCharged > 0 {
            let rate = cost / session.energyCharged
            return String(format: L("%@%.2f/kWh"), session.currency.rawValue, rate)
        }

        if session.expenseType == .fuel,
           let price = session.getFuelPricePerUnit() {
            return String(format: L("%@%.2f/%@"), session.currency.rawValue, price, measurementSystem.volumeUnitLabel)
        }

        return nil
    }
}
