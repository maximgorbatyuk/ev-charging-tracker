//
//  IExpenseView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.10.2025.
//

protocol IExpenseView {

    func insertExpense(_ session: Expense)

    func getAddExpenseCurrency() -> Currency
}
