//
//  AppSectionHeader.swift
//  EVChargingTracker
//
//  Uppercase eyebrow header above a card or content block. See
//  docs/guidelines/design.md §6.6. Title is 13/600/0.3 UPPERCASE in inkSoft;
//  optional trailing action slot for "See all"-style buttons.
//

import SwiftUI

struct AppSectionHeader<Action: SwiftUI.View>: SwiftUI.View {
    private let title: String
    private let action: Action

    init(_ title: String, @ViewBuilder action: () -> Action) {
        self.title = title
        self.action = action()
    }

    var body: some SwiftUI.View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .textCase(.uppercase)
                .appFont(.footnote, weight: .semibold)
                .tracking(0.3)
                .foregroundColor(AppColors.inkSoft)
            Spacer(minLength: 0)
            action
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }
}

extension AppSectionHeader where Action == EmptyView {
    init(_ title: String) {
        self.init(title, action: { EmptyView() })
    }
}
