//
//  ShareFormViewModel.swift
//  ShareExtension
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation
import os

@MainActor
class ShareFormViewModel: ObservableObject {

    // MARK: - Published state

    @Published var selectedCarId: Int64?
    @Published var selectedExpenseType: ExpenseType = .other
    @Published var notes: String = ""
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    // MARK: - Data

    @Published var cars: [Car] = []
    @Published var sharedInput: SharedInput?

    // MARK: - Callbacks

    var onComplete: (() -> Void)?
    var onCancel: (() -> Void)?

    private let logger = Logger(subsystem: "ShareExtension", category: "ShareFormViewModel")

    // MARK: - Validation

    var isCarSelected: Bool {
        selectedCarId != nil
    }

    var isFormValid: Bool {
        isCarSelected && !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSave: Bool {
        isFormValid && !isSaving
    }

    var hasCars: Bool {
        !cars.isEmpty
    }

    // MARK: - Configuration

    func configure(input: SharedInput, cars: [Car]) {
        self.sharedInput = input
        self.cars = cars

        // Auto-select car if only one exists
        if cars.count == 1 {
            selectedCarId = cars.first?.id
        }

        // Pre-fill notes based on input kind
        switch input.kind {
        case .link:
            if let url = input.url {
                notes = url.absoluteString
            }
        case .text:
            notes = input.text ?? ""
        }
    }

    // MARK: - Actions

    func save() {
        guard canSave else { return }

        isSaving = true
        errorMessage = nil

        guard let carId = selectedCarId,
              let car = cars.first(where: { $0.id == carId }) else {
            errorMessage = L("share.error.no_car_selected")
            isSaving = false
            return
        }

        let expense = Expense(
            date: Date(),
            energyCharged: 0,
            chargerType: .other,
            odometer: car.currentMileage,
            cost: nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isInitialRecord: false,
            expenseType: selectedExpenseType,
            currency: car.expenseCurrency,
            carId: carId
        )

        guard let insertedId = DatabaseManager.shared.expensesRepository?.insertSession(expense) else {
            logger.error("Failed to insert expense from Share Extension")
            errorMessage = L("share.error.save_failed")
            isSaving = false
            return
        }

        logger.info("Expense created from Share Extension with id: \(insertedId)")
        onComplete?()
    }

    func cancel() {
        onCancel?()
    }
}
