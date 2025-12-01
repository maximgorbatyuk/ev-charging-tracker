//
//  FormButtonsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 30.11.2025.
//

import SwiftUI

struct FormButtonsView: SwiftUICore.View {
    let onCancel: () -> Void
    let onSave: () -> Void
    
    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUICore.View {
        HStack(spacing: 16) {
            
            Button(L("Cancel"), action: onCancel)
                .buttonStyle(OutlinedButtonStyle(
                    backgroundColor: colorScheme == .dark ? .gray.opacity(0.05) : .white,
                    pressedColor: .red.opacity(0.15),
                    borderColor: .red,
                    textColor: .red
                ))

            Button(L("Save"), action: onSave)
                .buttonStyle(OutlinedButtonStyle(
                    backgroundColor: .green,
                    pressedColor: .green.opacity(0.7),
                    borderColor: .green,
                    textColor: .white
                ))
        }
    }
}

struct OutlinedButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let pressedColor: Color
    let borderColor: Color
    let textColor: Color

    func makeBody(configuration: Configuration) -> some SwiftUICore.View {
        configuration.label
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? pressedColor : backgroundColor)
            .foregroundColor(textColor)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .cornerRadius(20)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
