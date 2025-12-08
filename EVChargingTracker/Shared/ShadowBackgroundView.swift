//
//  ShadowBackgroundView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 08.12.2025.
//
import SwiftUI

struct ShadowBackgroundView: SwiftUI.View {
    var body: some SwiftUI.View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}
