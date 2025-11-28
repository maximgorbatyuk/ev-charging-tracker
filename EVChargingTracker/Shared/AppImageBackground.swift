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
        Image(colorScheme == .dark ? "logo-pattern-white" : "logo-pattern-black" )
            .resizable()
            .aspectRatio(contentMode: .fit)
            .opacity(0.05)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(x: -100, y: -100)
            .ignoresSafeArea()
    }
}
