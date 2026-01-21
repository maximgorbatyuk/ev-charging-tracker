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
    @State private var expenseToEdit: Expense? = nil

    @ObservedObject private var analytics = AnalyticsService.shared

    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUICore.View {
        ZStack(alignment: .bottomTrailing) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        if !viewModel.hasAnyExpense {
                            emptyStateView
                        } else {
                            if viewModel.selectedCarForExpenses != nil {
                                CostsBlockView(
                                    title: L("Total costs"),
                                    hint: nil,
                                    currency: viewModel.selectedCarForExpenses!.expenseCurrency,
                                    costsValue: viewModel.totalCost,
                                    perKilometer: false)
                            }

                            FilterButtonsView(
                                filterButtons: viewModel.filterButtons)
                            .padding(.bottom, 4)
                            .padding(.horizontal)

                            sortingSelectorView

                            if viewModel.expenses.isEmpty {
                                emptyStateForThisTypeView
                            } else {
                                VStack(spacing: 12) {

                                    Text(L("For editing or deleting record, please swipe left"))
                                        .font(.caption)
                                        .fontWeight(.regular)
                                        .padding(.horizontal)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    sessionsListView

                                    if viewModel.totalPages > 1 {
                                        paginationControlsView
                                    }
                                }
                            }
                        }

                        /// Extra padding at the bottom for FAB clearance
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.vertical)
                }
                .navigationTitle(L("All car expenses"))
                .navigationBarTitleDisplayMode(.automatic)
                .sheet(isPresented: $showingAddSession) {

                    let selectedCar = viewModel.selectedCarForExpenses
                    AddExpenseView(
                        defaultExpenseType: nil,
                        defaultCurrency: viewModel.getAddExpenseCurrency(),
                        selectedCar: selectedCar,
                        allCars: viewModel.getAllCars(),
                        onAdd: { newExpenseResult in

                            viewModel.saveNewExpense(newExpenseResult)
                            analytics.trackEvent(
                                "expense_record_added",
                                properties: [
                                    "screen": viewModel.analyticsScreenName
                                ])
                        })
                }
                .sheet(item: $expenseToEdit) { expense in
                    let selectedCar = viewModel.selectedCarForExpenses
                    AddExpenseView(
                        defaultExpenseType: expense.expenseType,
                        defaultCurrency: expense.currency,
                        selectedCar: selectedCar,
                        allCars: viewModel.getAllCars(),
                        existingExpense: expense,
                        onAdd: { updatedExpenseResult in
                            viewModel.updateExistingExpense(
                                updatedExpenseResult,
                                expenseToEdit: expense)

                            analytics.trackEvent(
                                "expense_record_updated",
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

            floatingAddButton
        }
    }

    private var floatingAddButton: some SwiftUICore.View {
        Button(action: {
            showingAddSession = true
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
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

    private var emptyStateForThisTypeView: some SwiftUICore.View {
       VStack(spacing: 16) {
           Image(systemName: "dollarsign.circle.fill")
               .font(.system(size: 64))
               .foregroundColor(.gray.opacity(0.5))

           Text(L("No expenses of this type yet"))
               .font(.title3)
               .foregroundColor(.gray)
       }
       .padding(.top, 60)
   }

    private var sortingSelectorView: some SwiftUICore.View {
        HStack {
            Text(L("Sort by"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Picker(L("Sort by"), selection: sortingOptionBinding) {
                ForEach(ExpensesSortingOption.allCases, id: \.self) { option in
                    Text(option.localizedTitle).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var sortingOptionBinding: SwiftUI.Binding<ExpensesSortingOption> {
        SwiftUI.Binding(
            get: { viewModel.selectedSortingOption },
            set: { viewModel.setSortingOption($0) }
        )
    }

    private var sessionsListView: some SwiftUICore.View {
        List {
            ForEach(viewModel.expenses) { session in
                SessionCard(session: session)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            analytics.trackEvent(
                                "expense_delete_button_clicked",
                                properties: [
                                    "button_name": "delete",
                                    "screen": viewModel.analyticsScreenName,
                                    "action": "delete_expense"
                                ])

                            expenseToDelete = session
                            showingDeleteConfirmation = true
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }

                        Button {
                            analytics.trackEvent(
                                "expense_edit_button_clicked",
                                properties: [
                                    "button_name": "edit",
                                    "screen": viewModel.analyticsScreenName,
                                    "action": "edit_expense"
                                ])

                            expenseToEdit = session
                        } label: {
                            Label(L("Edit"), systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(minHeight: CGFloat(viewModel.expenses.count) * 120)
    }
    
    private var paginationControlsView: some SwiftUICore.View {
        VStack(spacing: 12) {
            // Navigation buttons
            HStack(spacing: 16) {
                // Previous button
                Button(action: {
                    viewModel.goToPreviousPage()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(L("Previous"))
                    }
                    .font(.subheadline)
                    .foregroundColor(viewModel.currentPage > 1 ? .blue : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .disabled(viewModel.currentPage <= 1)
                
                // Current page indicator
                Text("\(viewModel.currentPage)")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(minWidth: 40)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                
                // Next button
                Button(action: {
                    viewModel.goToNextPage()
                }) {
                    HStack(spacing: 4) {
                        Text(L("Next"))
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(viewModel.currentPage < viewModel.totalPages ? .blue : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .disabled(viewModel.currentPage >= viewModel.totalPages)
            }
            
            // Information text
            Text(String(format: L("Total records: %d, total pages: %d"), viewModel.totalRecords, viewModel.totalPages))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
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

#Preview {
    ExpensesView()
}
