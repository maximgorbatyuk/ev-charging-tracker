//
//  IExpenseView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.10.2025.
//

protocol IExpenseView {

    func addExpense(_ session: Expense)

    func getDefaultCurrency() -> Currency
}
