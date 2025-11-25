//
//  AppImageBackground.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 24.11.2025.
//

import SwiftUI

struct AppImageBackground: SwiftUI.View {
    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUI.View {
        VStack(alignment: .center, spacing: 20) {
            GeometryReader { geometry in
                Image(colorScheme == .dark ? "logo-white" : "logo-black" )
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width / 2)
                    .opacity(0.03)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
        }
    }
}
