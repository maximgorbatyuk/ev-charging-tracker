//
//  FilterButtonsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 06.12.2025.
//

import SwiftUI

struct FilterButtonsView: SwiftUICore.View {

    let filterButtons: [FilterButtonItem]
    @Environment(\.colorScheme) var colorScheme

    func executeButtonAction(_ button: FilterButtonItem) {
        filterButtons.forEach { $0.deselect() }
        button.action()
    }

    var body: some SwiftUICore.View {
        HStack(spacing: 8) {
            ForEach(filterButtons, id: \.id) { button in

                Button(button.title) {
                    executeButtonAction(button)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.vertical, 12)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .animation(.easeInOut, value: button.isSelected)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(button.isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(button.isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
}
