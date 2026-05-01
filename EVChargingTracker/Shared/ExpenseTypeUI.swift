//
//  ExpenseTypeUI.swift
//  EVChargingTracker
//
//  UI-layer extension on `ExpenseType`. Lives outside `BusinessLogic/` so the
//  model layer stays SwiftUI-free. See docs/guidelines/design.md §7.2 for the
//  category-color mapping.
//

import SwiftUI

extension ExpenseType {
    var color: Color {
        switch self {
        case .charging: return AppColors.green
        case .maintenance: return AppColors.orange
        case .repair: return AppColors.red
        case .carwash: return AppColors.blue
        case .other: return AppColors.gray
        }
    }
}
