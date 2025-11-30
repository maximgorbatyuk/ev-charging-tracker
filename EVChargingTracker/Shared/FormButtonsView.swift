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

    var body: some SwiftUICore.View {
        HStack(spacing: 16) {
            Button(L("Cancel")) {
                onCancel()
            }
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.clear)
            .foregroundColor(.red)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.red, lineWidth: 1.5)
            )
            .cornerRadius(20)

            Button(L("Save")) {
                onSave()
            }
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.green)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.green, lineWidth: 1.5)
            )
            .cornerRadius(20)
        }
    }
}
