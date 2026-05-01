//
//  AppColors.swift
//  EVChargingTracker
//
//  Design-system color tokens. Derived from docs/guidelines/design.md §3.
//  Brand greens / orange stay constant across modes; surfaces, ink, and the
//  *Soft variants flip via dynamic UIColor providers.
//

import SwiftUI
import UIKit

enum AppColors {
    // Brand — solid hex, identical in light and dark.
    static let green     = Color(red: 15 / 255,  green: 169 / 255, blue: 104 / 255)
    static let greenDeep = Color(red: 10 / 255,  green: 122 / 255, blue: 75 / 255)
    static let greenLeaf = Color(red: 76 / 255,  green: 195 / 255, blue: 136 / 255)

    // Orange — sRGB approximation of oklch(0.72 0.18 28) per §3.1.
    static let orange     = Color(red: 255 / 255, green: 138 / 255, blue: 77 / 255)
    static let orangeDeep = Color(red: 229 / 255, green: 100 / 255, blue: 31 / 255)

    // System pops (icon badges, category tags, chart series).
    static let blue   = Color(red: 10 / 255,  green: 132 / 255, blue: 255 / 255)
    static let indigo = Color(red: 94 / 255,  green: 92 / 255,  blue: 230 / 255)
    static let purple = Color(red: 175 / 255, green: 82 / 255,  blue: 222 / 255)
    static let pink   = Color(red: 255 / 255, green: 55 / 255,  blue: 95 / 255)
    static let red    = Color(red: 255 / 255, green: 69 / 255,  blue: 58 / 255)
    static let yellow = Color(red: 255 / 255, green: 214 / 255, blue: 10 / 255)
    static let teal   = Color(red: 100 / 255, green: 210 / 255, blue: 255 / 255)
    static let gray   = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)

    // Surfaces — iOS grouped vocabulary.
    static let bg          = dyn(light: 0xF2F2F7, dark: 0x000000)
    static let surface     = dyn(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let surfaceAlt  = dyn(light: 0xECEAEF, dark: 0x2C2C2E)
    static let surfaceHigh = dyn(light: 0xFFFFFF, dark: 0x2C2C2E)

    // Ink hierarchy — 4 levels.
    static let ink      = dyn(light: 0x000000, dark: 0xFFFFFF)
    static let inkSoft  = dynAlpha(
        light: (0x3C3C43, 0.62),
        dark:  (0xEBEBF5, 0.62)
    )
    static let inkFaint = dynAlpha(
        light: (0x3C3C43, 0.32),
        dark:  (0xEBEBF5, 0.32)
    )
    static let inkGhost = dynAlpha(
        light: (0x3C3C43, 0.14),
        dark:  (0xEBEBF5, 0.16)
    )

    // Dividers / hairlines.
    static let divider = dynAlpha(
        light: (0x3C3C43, 0.10),
        dark:  (0x545458, 0.45)
    )
    static let hairline = dynAlpha(
        light: (0x3C3C43, 0.18),
        dark:  (0x545458, 0.60)
    )

    // Soft brand fills — pastel hex in light, alpha in dark.
    static let greenSoft = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 15 / 255, green: 169 / 255, blue: 104 / 255, alpha: 0.16)
            : UIColor(hex: 0xE3F5EC)
    })

    static let orangeSoft = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 255 / 255, green: 138 / 255, blue: 77 / 255, alpha: 0.20)
            : UIColor(hex: 0xFCE5D4)
    })

    // Soft system-pop fills — pastel hex in light, rgba(tint, 0.18) in dark.
    static let blueSoft = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 10 / 255, green: 132 / 255, blue: 255 / 255, alpha: 0.18)
            : UIColor(hex: 0xE0EBFF)
    })

    static let redSoft = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 255 / 255, green: 69 / 255, blue: 58 / 255, alpha: 0.18)
            : UIColor(hex: 0xFFE1DF)
    })

    static let tealSoft = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 100 / 255, green: 210 / 255, blue: 255 / 255, alpha: 0.18)
            : UIColor(hex: 0xDCF1FA)
    })

    private static func dyn(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    private static func dynAlpha(
        light: (hex: UInt32, alpha: CGFloat),
        dark: (hex: UInt32, alpha: CGFloat)
    ) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: dark.hex, alpha: dark.alpha)
                : UIColor(hex: light.hex, alpha: light.alpha)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8)  & 0xFF) / 255,
            blue:  CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
