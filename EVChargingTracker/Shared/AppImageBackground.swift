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
        GeometryReader { geometry in
            VStack(spacing: 30) {
                ForEach(0..<20, id: \.self) { row in
                    HStack(spacing: 30) {
                        ForEach(0..<10, id: \.self) { column in
                            Image(colorScheme == .dark ? "logo-white" : "logo-black" )
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .opacity(0.02 + Double(row + column) * 0.003)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(x: -100, y: -100) // Adjust to position pattern
        }
        .ignoresSafeArea()
    }
}
