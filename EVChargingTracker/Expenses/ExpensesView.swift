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
    @State private var showingDeleteConfirmation: Bool = false
    @State private var expenseToDelete: Expense? = nil

    @ObservedObject private var analytics = AnalyticsService.shared

    @Environment(\.colorScheme) var colorScheme

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
                                Text(L("Add Expense"))
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

                        if viewModel.totalCost > 0 {
                            CostsBlockView(
                                title: L("Total costs"),
                                hint: nil,
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.totalCost,
                                perKilometer: false)
                        }

                        if viewModel.expenses.isEmpty {
                            emptyStateView
                        } else {
                            
                            HStack(spacing: 8) {
                                ForEach(viewModel.filterButtons, id: \.id) { button in
                                    FilterButton(
                                        button: button
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            sessionsListView
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(L("All car expenses"))
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showingAddSession) {
                
                let selectedCar = viewModel.selectedCarForExpenses
                AddExpenseView(
                    defaultExpenseType: nil,
                    defaultCurrency: viewModel.getDefaultCurrency(),
                    selectedCar: selectedCar,
                    onAdd: { newExpenseResult in

                        viewModel.saveNewExpense(newExpenseResult)
                        analytics.trackEvent(
                            "expense_record_added",
                            properties: [
                                "screen": viewModel.analyticsScreenName
                            ])
                    })
            }
            .onAppear {
                analytics.trackScreen(viewModel.analyticsScreenName)
                viewModel.loadSessions()
            }
            .refreshable {
                viewModel.loadSessions()
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                deleteConfirmationAlert()
            }
         }
     }

     private var emptyStateView: some SwiftUICore.View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))

            Text(L("No expenses yet"))
                .font(.title3)
                .foregroundColor(.gray)
            
            Text(L("Add your first expense to start tracking"))
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
                        analytics.trackEvent("expense_delete_button_clicked", properties: [
                                "button_name": "delete",
                                "screen": viewModel.analyticsScreenName,
                                "action": "delete_expense"
                            ])

                        // ask for confirmation before deleting
                        expenseToDelete = session
                        showingDeleteConfirmation = true
                    })
            }
        }
        .padding(.horizontal)
    }
    
    // Confirmation alert attached to the view
    private func deleteConfirmationAlert() -> Alert {
        let title = Text(L("Delete expense"))
        let message = Text(L("Delete selected expense? This action cannot be undone."))

        return Alert(
            title: title,
            message: message,
            primaryButton: .destructive(Text(L("Delete"))) {
                if let e = expenseToDelete {
                    viewModel.deleteSession(e)

                    analytics.trackEvent(
                        "expense_deleted",
                        properties: [
                            "screen": viewModel.analyticsScreenName
                        ])
                }
                expenseToDelete = nil
            },
            secondaryButton: .cancel {
                expenseToDelete = nil
            }
        )
    }
}

struct FilterButton: SwiftUICore.View {

    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var button: FilterButtonItem

    var body: some SwiftUICore.View {
        Button(button.title) {
            button.action()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(colorScheme == .dark ? .white : .black)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(button.isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(button.isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ExpensesView()
}
