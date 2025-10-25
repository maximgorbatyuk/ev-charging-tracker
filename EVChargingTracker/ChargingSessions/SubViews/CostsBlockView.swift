//
//  CostsBlockView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import SwiftUI

struct CostsBlockView: SwiftUICore.View {

    let title: String
    let hint: String?
    let currency: Currency
    let costsValue: Double
    let perKilometer: Bool

    @Environment(\.colorScheme) var colorScheme

    @State private var showingHelp = false
    @State private var textToShowInSheet = ""
    
    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()

                if let hint = hint {
                    
                    Button(action: {
                        textToShowInSheet = hint
                        showingHelp.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                            .help(hint)
                    }
                    .popover(isPresented: $showingHelp) {
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hint")
                                .font(.headline)
                            
                            Text(hint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .presentationCompactAdaptation(.popover)
                        .frame(width: 250)
                    }
                }
            }

            HStack(alignment: .lastTextBaseline) {
                Text(String(format: "\(currency.rawValue)%.2f", costsValue))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                if (perKilometer) {
                    Text("per km")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
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
        hint: nil,
        currency: .kzt,
        costsValue: 45,
        perKilometer: true
    )
}
