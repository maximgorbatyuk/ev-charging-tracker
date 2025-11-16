//
//  EditDefaultCurrencyView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import SwiftUI

struct EditDefaultCurrencyView: SwiftUICore.View {
    @State var selectedCurrency: Currency?
    let onSave: (Currency) -> Void

    @Environment(\.dismiss) var dismiss

    var body: some SwiftUICore.View {
        NavigationView {
            Form {
                Section() {
                    Picker(L("Select currency"), selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                    
                }
            }
            .navigationTitle(L("Select default currency"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Save")) {
                        saveCurrency()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveCurrency() {

        guard let selectedCurrencyUnwrapped = selectedCurrency else {
            return
        }

        onSave(selectedCurrencyUnwrapped)
        dismiss()
    }
}

#Preview {
    EditDefaultCurrencyView(
        selectedCurrency: .usd,
        onSave: { newCurrency in
            print("selected: \(newCurrency)")
        })
}
