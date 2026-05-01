//
//  AppCard.swift
//  EVChargingTracker
//
//  Design-system card surface. See docs/guidelines/design.md §6.1.
//  Light mode: 0.5pt drop shadow. Dark mode: no shadow, 1px inset hairline.
//  `pad: 0` lets a chart bleed to the card edge.
//

import SwiftUI

struct AppCard<Content: SwiftUICore.View>: SwiftUICore.View {
    @Environment(\.colorScheme) private var colorScheme

    private let pad: CGFloat
    private let radius: CGFloat
    private let fillsWidth: Bool
    private let content: () -> Content

    init(
        pad: CGFloat = 16,
        radius: CGFloat = 20,
        fillsWidth: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.pad = pad
        self.radius = radius
        self.fillsWidth = fillsWidth
        self.content = content
    }

    var body: some SwiftUICore.View {
        content()
            .padding(pad)
            .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(AppColors.surface)
            )
            .overlay(
                // design.md §5.3: dark-mode cards use `rgba(255,255,255,0.08)`
                // inset stroke. Not `AppColors.hairline` — that token is for
                // button strokes (§3.4) and uses a different alpha.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.04),
                radius: 0.5,
                x: 0,
                y: 0.5
            )
    }
}
