//
//  CostsBlockView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import SwiftUI

struct CostsBlockView: SwiftUICore.View {

    let title: String
    let hint: String?
    let currency: Currency
    let costsValue: Double
    let perKilometer: Bool
    var measurementSystem: MeasurementSystem = .metric
    var distanceCostBasis: DistanceCostBasis = .perUnit

    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var showingHelp = false

    /// Suffix shown next to the value, e.g. "per km" or "per 100 mi".
    private var perDistanceSuffix: String {
        switch (measurementSystem, distanceCostBasis) {
        case (.imperial, .perUnit): return L("per mi")
        case (.imperial, .perHundredUnits): return L("per 100 mi")
        case (.metric, .perUnit): return L("per km")
        case (.metric, .perHundredUnits): return L("per 100 km")
        }
    }

    func getFormattedDigits() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = " "

        let number = NSNumber(value: costsValue)
        return formatter.string(from: number) ?? "—"
    }

    var body: some SwiftUICore.View {
        AppCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .textCase(.uppercase)
                        .appFont(.caption2, weight: .semibold)
                        .tracking(0.3)
                        .foregroundColor(AppColors.inkSoft)
                    Spacer()

                    if let hint = hint {
                        Button(action: {
                            analytics.trackEvent(
                                "hint_button_clicked",
                                properties: ["title": title]
                            )
                            showingHelp.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(AppColors.inkSoft)
                                .help(hint)
                        }
                        .sheet(isPresented: $showingHelp) {
                            CostHintModalView(hint: hint, showsBasisSwitch: perKilometer)
                                .presentationDetents([.medium])
                                .presentationDragIndicator(.visible)
                        }
                    }
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(getFormattedDigits())
                            .appFont(.title, weight: .bold)
                            .monospacedDigit()
                            .tracking(-1.0)
                            .foregroundColor(AppColors.ink)
                        Text(currency.rawValue)
                            .appFont(.title2, weight: .bold)
                            .foregroundColor(AppColors.ink)
                    }

                    if perKilometer {
                        Text(perDistanceSuffix)
                            .appFont(.footnote, weight: .medium)
                            .foregroundColor(AppColors.inkSoft)
                    }
                }
            }
        }
    }

}

#Preview {
    CostsBlockView(
        title: L("How much one kilometer costs you"),
        hint: nil,
        currency: .kzt,
        costsValue: 45,
        perKilometer: true
    )
    .padding()
}
