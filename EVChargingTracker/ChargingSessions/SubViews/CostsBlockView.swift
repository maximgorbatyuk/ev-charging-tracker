//
//  CostsBlockView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import SwiftUI

struct CostsBlockView: SwiftUICore.View {

    let title: String
    let currency: Currency
    let costsValue: Double
    
    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.black)

            Text(String(format: "\(currency.rawValue)%.2f", costsValue))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

#Preview {
    CostsBlockView(
        title: "How much one kilometer costs you",
        currency: .kzt,
        costsValue: 45
    )
}
