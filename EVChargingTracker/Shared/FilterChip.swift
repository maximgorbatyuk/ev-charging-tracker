//
//  FilterChip.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 31.01.2026.
//
//  Circuit chip per design.md §6.2.
//

import SwiftUI

struct FilterChip: SwiftUICore.View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some SwiftUICore.View {
        Button(action: action) {
            Text(title)
                .appFont(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? AppColors.orangeDeep : AppColors.inkSoft)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? AppColors.orangeSoft : AppColors.surfaceAlt)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        FilterChip(title: "All", isSelected: true) {}
        FilterChip(title: "Charging", isSelected: false) {}
        FilterChip(title: "Maintenance", isSelected: false) {}
    }
    .padding()
}
