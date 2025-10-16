//
//  ExpensesView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.10.2025.
//

import SwiftUI

struct ExpensesView: SwiftUICore.View {

    @StateObject private var viewModel = ExpensesViewModel()
    @State private var showingAddSession = false

    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {

                ScrollView {
                    VStack(spacing: 20) {

                        Button(action: {
                            showingAddSession = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Expense")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Total Cost
                        if viewModel.totalCost > 0 {
                            totalCostView
                        }

                        // Sessions List
                        if viewModel.expenses.isEmpty {
                            emptyStateView
                        } else {
                            sessionsListView
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("All car expenses")
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showingAddSession) {
                AddSessionView(
                    defaultExpenseType: nil,
                    defaultCurrency: viewModel.getDefaultCurrency(),
                    showFirstTrackingRecordToggle: viewModel.expenses.isEmpty,
                    onAdd: { newExpense in
                        viewModel.addExpense(newExpense) // closure receives Expense param
                    })
            }
        }
    }

    private var emptyStateView: some SwiftUICore.View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))

            Text("No expenses yet")
                .font(.title3)
                .foregroundColor(.gray)
            
            Text("Add your first expense to start tracking")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.9))
        }
        .padding(.top, 60)
    }
    
    private var sessionsListView: some SwiftUICore.View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.expenses) { session in
                SessionCard(
                    session: session,
                    onDelete: {
                        viewModel.deleteSession(session)
                    })
            }
        }
        .padding(.horizontal)
    }

    // TODO mgorbatyuk: void copypasteed code
    private var totalCostView: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total expenses")
                .font(.subheadline)
                .foregroundColor(.green)

            Text(String(format: "\(viewModel.defaultCurrency.rawValue)%.2f", viewModel.totalCost))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

#Preview {
    ExpensesView()
}
