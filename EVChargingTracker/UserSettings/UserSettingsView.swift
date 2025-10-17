//
//  UserSettingsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

import SwiftUI

struct UserSettingsView: SwiftUICore.View {

    @StateObject private var viewModel = UserSettingsViewModel()
    @State private var showEditCurrencyModal: Bool = false

    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {

                ScrollView {
                    VStack(alignment: .leading) {

                        HStack {
                            Text("Currency")
                                .fontWeight(.semibold)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                showEditCurrencyModal = true
                            }) {
                                Text("\(String(describing: viewModel.defaultCurrency).uppercased()) (\(viewModel.defaultCurrency.rawValue))")
                                    .fontWeight(.semibold)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            
                        }
                        Divider()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("User settings")
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showEditCurrencyModal) {
                EditDefaultCurrencyView(
                    selectedCurrency: viewModel.getDefaultCurrency(),
                    onSave: { newCurrency in
                        viewModel.saveDefaultCurrency(newCurrency)
                    })
            }
        }
    }
}

#Preview {
    UserSettingsView()
}
