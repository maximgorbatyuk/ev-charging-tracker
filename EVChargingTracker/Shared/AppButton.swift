//
//  AppButton.swift
//  EVChargingTracker
//
//  Design-system button. See docs/guidelines/design.md §6.3.
//  Sizes: lg 52/14, md 44/12, sm 34/10. Kinds: primary, green, accent,
//  surface, tinted, ghost, outlined.
//

import SwiftUI

struct AppButton: SwiftUI.View {
    enum Kind {
        case primary
        case green
        case accent
        case surface
        case tinted
        case ghost
        case outlined
    }

    enum Size {
        case lg
        case md
        case sm
    }

    @Environment(\.colorScheme) private var colorScheme

    private let title: String
    private let kind: Kind
    private let size: Size
    private let icon: String?
    private let fullWidth: Bool
    private let action: () -> Void

    init(
        _ title: String,
        kind: Kind = .primary,
        size: Size = .lg,
        icon: String? = nil,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.kind = kind
        self.size = size
        self.icon = icon
        self.fullWidth = fullWidth
        self.action = action
    }

    var body: some SwiftUI.View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: iconPoint, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text(title)
                    .appFont(textStyle, weight: .semibold)
                    .tracking(-0.2)
            }
            .foregroundColor(palette.fg)
            .padding(.horizontal, size == .sm ? 12 : 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(palette.bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(palette.stroke ?? Color.clear, lineWidth: palette.stroke == nil ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var height: CGFloat {
        switch size {
        case .lg: return 52
        case .md: return 44
        case .sm: return 34
        }
    }

    private var radius: CGFloat {
        switch size {
        case .lg: return 14
        case .md: return 12
        case .sm: return 10
        }
    }

    private var textStyle: AppFontStyle {
        switch size {
        case .lg: return .body
        case .md: return .subheadline
        case .sm: return .footnote
        }
    }

    private var iconPoint: CGFloat {
        switch size {
        case .lg: return 17
        case .md: return 15
        case .sm: return 13
        }
    }

    private var palette: (bg: Color, fg: Color, stroke: Color?) {
        switch kind {
        case .primary:
            return (AppColors.ink, colorScheme == .dark ? .black : .white, nil)
        case .green:
            return (AppColors.green, .white, nil)
        case .accent:
            return (AppColors.orange, .white, nil)
        case .surface:
            return (AppColors.surface, AppColors.ink, AppColors.hairline)
        case .tinted:
            return (AppColors.surfaceAlt, AppColors.ink, nil)
        case .ghost:
            return (.clear, AppColors.blue, nil)
        case .outlined:
            return (.clear, AppColors.red, AppColors.red.opacity(0.5))
        }
    }
}
