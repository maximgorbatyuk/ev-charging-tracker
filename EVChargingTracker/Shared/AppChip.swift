//
//  AppChip.swift
//  EVChargingTracker
//
//  Design-system pill chip. See docs/guidelines/design.md §6.2.
//  Sizes: sm (20pt), md (26pt). Optional leading SF Symbol.
//

import SwiftUI

struct AppChip: SwiftUI.View {
    enum Tint {
        case green
        case orange
        case blue
        case red
        case gray
        case ink
    }

    enum Size {
        case sm
        case md
    }

    @Environment(\.colorScheme) private var colorScheme

    private let text: String
    private let tint: Tint
    private let size: Size
    private let icon: String?

    init(
        _ text: String,
        tint: Tint = .gray,
        size: Size = .md,
        icon: String? = nil
    ) {
        self.text = text
        self.tint = tint
        self.size = size
        self.icon = icon
    }

    var body: some SwiftUI.View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: iconPoint, weight: .semibold))
            }
            Text(text)
                .appFont(textStyle, weight: .semibold)
                .tracking(textTracking)
        }
        .foregroundColor(palette.fg)
        .padding(.horizontal, horizontalPad)
        .frame(height: height)
        .background(
            Capsule(style: .continuous).fill(palette.bg)
        )
    }

    private var height: CGFloat {
        switch size {
        case .sm: return 20
        case .md: return 26
        }
    }

    private var horizontalPad: CGFloat {
        switch size {
        case .sm: return 8
        case .md: return 10
        }
    }

    private var textStyle: AppFontStyle {
        switch size {
        case .sm: return .caption2
        case .md: return .caption
        }
    }

    private var textTracking: CGFloat {
        switch size {
        case .sm: return -0.1
        case .md: return -0.2
        }
    }

    private var iconPoint: CGFloat {
        switch size {
        case .sm: return 10
        case .md: return 11
        }
    }

    private var palette: (bg: Color, fg: Color) {
        switch tint {
        case .green:  return (AppColors.greenSoft,  AppColors.greenDeep)
        case .orange: return (AppColors.orangeSoft, AppColors.orangeDeep)
        case .blue:   return (AppColors.blueSoft,   AppColors.blue)
        case .red:    return (AppColors.redSoft,    AppColors.red)
        case .gray:   return (AppColors.surfaceAlt, AppColors.inkSoft)
        // `.ink` flips both bg and fg via opposite mechanisms so the spec
        // (§6.2: `#000 bg / #FFF fg` light → `#FFF bg / #000 fg` dark) holds.
        // bg = AppColors.ink (auto-flips white↔black). fg = the inverse
        // (manual ternary), since AppColors.ink would just match bg.
        case .ink:    return (AppColors.ink,        colorScheme == .dark ? .black : .white)
        }
    }
}
