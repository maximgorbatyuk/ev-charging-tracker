//
//  CarDetailsSectionView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct CarDetailsSectionView<Content: SwiftUI.View>: SwiftUI.View {

    let title: String
    let iconName: String
    let iconColor: Color
    var itemCount: Int = 0
    var badgeCount: Int = 0
    let onSeeAll: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some SwiftUI.View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.headline)
                        .foregroundColor(iconColor)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    } else if itemCount > 0 {
                        Text("\(itemCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(iconColor)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text(L("See all"))
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            content()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
