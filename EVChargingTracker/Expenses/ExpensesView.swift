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
    @ObservedObject private var loc = LocalizationManager.shared

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

                        // Total Cost
                        if viewModel.totalCost > 0 {
                            CostsBlockView(
                                title: L("Total costs"),
                                hint: nil,
                                currency: viewModel.defaultCurrency,
                                costsValue: viewModel.totalCost,
                                perKilometer: false)
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
            .navigationTitle(L("All car expenses"))
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showingAddSession) {
                
                let selectedCar = viewModel.selectedCarForExpenses
                AddExpenseView(
                    defaultExpenseType: nil,
                    defaultCurrency: viewModel.getDefaultCurrency(),
                    selectedCar: selectedCar,
                    onAdd: { newExpenseResult in
                        var carId: Int64? = nil
                        if (selectedCar == nil) {
                            if (newExpenseResult.carName == nil) {
                                
                                // TODO mgorbatyuk: show error alert to user
                                print("Error: First expense must have a car name!")
                                return
                            }
                            
                            let now = Date()
                            let car = Car(
                                id: nil,
                                name: newExpenseResult.carName!,
                                selectedForTracking: true,
                                batteryCapacity: newExpenseResult.batteryCapacity,
                                expenseCurrency: newExpenseResult.initialExpenseForNewCar!.currency,
                                currentMileage: newExpenseResult.initialExpenseForNewCar!.odometer,
                                initialMileage: newExpenseResult.initialExpenseForNewCar!.odometer,
                                milleageSyncedAt: now,
                                createdAt: now)

                            carId = viewModel.addCar(car: car)
                            newExpenseResult.initialExpenseForNewCar!.setCarId(carId!)
                            viewModel.addExpense(newExpenseResult.initialExpenseForNewCar!)
                        } else {
                            carId = selectedCar!.id
                            selectedCar!.updateMileage(newMileage: newExpenseResult.expense.odometer)
                            _ = viewModel.updateMilleage(selectedCar!)
                        }

                        newExpenseResult.expense.setCarId(carId)
                        viewModel.addExpense(newExpenseResult.expense)
                    })
            }
            .onAppear {
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
        let message: Text
        if let e = expenseToDelete {
            // Show date and optional amount
            let dateText = e.date.formatted(date: .abbreviated, time: .omitted)
            if let cost = e.cost {
                let amount = String(format: "%@%.2f", e.currency.rawValue, cost)
                let messageString = String(format: L("Delete expense on %@ with amount %@? This action cannot be undone."), dateText, amount)
                message = Text(messageString)
            } else {
                let messageString = String(format: L("Delete expense on %@? This action cannot be undone."), dateText)
                message = Text(messageString)
            }
        } else {
            message = Text(L("Delete selected expense? This action cannot be undone."))
        }

        return Alert(
            title: title,
            message: message,
            primaryButton: .destructive(Text(L("Delete"))) {
                if let e = expenseToDelete {
                    viewModel.deleteSession(e)
                }
                expenseToDelete = nil
            },
            secondaryButton: .cancel {
                expenseToDelete = nil
            }
        )
    }
}

#Preview {
    ExpensesView()
}
