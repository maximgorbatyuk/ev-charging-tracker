//
//  ConsumptionHintModalView.swift
//  EVChargingTracker
//

import SwiftUI

struct ConsumptionHintModalView: SwiftUICore.View {

    let hint: String

    @ObservedObject private var basisManager = ConsumptionBasisManager.shared
    @Environment(\.dismiss) private var dismiss

    /// The basis the switch button moves to (the one not currently selected).
    private var targetBasis: DistanceCostBasis {
        basisManager.currentBasis == .perUnit ? .perHundredUnits : .perUnit
    }

    private var switchButtonTitle: String {
        targetBasis == .perHundredUnits
            ? L("Switch to per 100 km/mi")
            : L("Switch to per 1 km/mi")
    }

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("Hint"))
                .appFont(.headline)
                .foregroundColor(AppColors.ink)

            Text(hint)
                .appFont(.body)
                .foregroundColor(AppColors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            AppButton(
                switchButtonTitle,
                kind: .accent,
                size: .lg,
                icon: "arrow.left.arrow.right",
                fullWidth: true,
                action: {
                    basisManager.setBasis(targetBasis)
                    dismiss()
                }
            )

            Spacer()

            AppButton(
                L("Close"),
                kind: .tinted,
                size: .lg,
                fullWidth: true,
                action: { dismiss() }
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.bg)
    }
}

#Preview {
    ConsumptionHintModalView(
        hint: L("Average energy your car consumes over a distance. Switch between per 100 km/mi and per 1 km/mi.")
    )
}
