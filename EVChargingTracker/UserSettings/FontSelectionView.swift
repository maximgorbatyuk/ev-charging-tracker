//
//  FontSelectionView.swift
//  EVChargingTracker
//
//  Modal sheet that lets the user pick between `AppFontFamily` cases.
//  Each row renders its display name in its own family so the user can
//  preview the look before committing.
//

import SwiftUI

struct FontSelectionView: SwiftUICore.View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var fontFamily = AppFontFamilyManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    private let sampleText = "Charge 4.2 kWh · $0.13 / km"

    var body: some SwiftUICore.View {
        NavigationStack {
            List {
                ForEach(AppFontFamily.allCases, id: \.self) { family in
                    Button {
                        fontFamily.setFamily(family)
                    } label: {
                        row(for: family)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(L("Font"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Close")) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for family: AppFontFamily) -> some SwiftUICore.View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(family.displayName)
                    .font(previewFont(.headline, family: family, weight: .semibold))
                    .foregroundColor(.primary)

                Text(sampleText)
                    .font(previewFont(.subheadline, family: family))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            if family == fontFamily.currentFamily {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .accessibilityLabel(L("Selected"))
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private func previewFont(
        _ style: AppFontStyle,
        family: AppFontFamily,
        weight: Font.Weight? = nil
    ) -> Font {
        AppFont.resolve(
            style: style,
            language: localization.currentLanguage,
            family: family,
            weight: weight
        )
    }
}
