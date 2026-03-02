//
//  ShareFormViewModel.swift
//  ShareExtension
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation
import os

enum ShareEntityType: String, CaseIterable {
    case expense
    case idea
    case document

    var displayName: String {
        switch self {
        case .expense: return L("share.entity.expense")
        case .idea: return L("share.entity.idea")
        case .document: return L("share.entity.document")
        }
    }
}

@MainActor
class ShareFormViewModel: ObservableObject {

    // MARK: - Published state

    @Published var selectedEntityType: ShareEntityType = .expense
    @Published var selectedCarId: Int64?
    @Published var selectedExpenseType: ExpenseType = .other
    @Published var notes: String = ""
    @Published var ideaTitle: String = ""
    @Published var ideaUrl: String = ""
    @Published var ideaDescription: String = ""
    @Published var documentTitle: String = ""
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    // MARK: - Data

    @Published var cars: [Car] = []
    @Published var sharedInput: SharedInput?

    // MARK: - Callbacks

    var onComplete: (() -> Void)?
    var onCancel: (() -> Void)?

    private let logger = Logger(subsystem: "ShareExtension", category: "ShareFormViewModel")

    // MARK: - Computed properties

    var isCarSelected: Bool {
        selectedCarId != nil
    }

    var isFormValid: Bool {
        guard isCarSelected else { return false }

        switch selectedEntityType {
        case .expense:
            return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .idea:
            return !ideaTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .document:
            return sharedInput?.tempFileURL != nil
        }
    }

    var canSave: Bool {
        isFormValid && !isSaving
    }

    var hasCars: Bool {
        !cars.isEmpty
    }

    var availableEntityTypes: [ShareEntityType] {
        guard let input = sharedInput else { return [.expense] }
        switch input.kind {
        case .link:
            return [.expense, .idea]
        case .text:
            return [.expense, .idea]
        case .file:
            return [.expense, .document]
        }
    }

    // MARK: - Configuration

    func configure(input: SharedInput, cars: [Car]) {
        self.sharedInput = input
        self.cars = cars

        // Auto-select car if only one exists
        if cars.count == 1 {
            selectedCarId = cars.first?.id
        }

        // Pre-fill fields based on input kind
        switch input.kind {
        case .link:
            if let url = input.url {
                notes = url.absoluteString
                ideaUrl = url.absoluteString
                ideaTitle = input.suggestedTitle ?? url.host ?? ""
            }
        case .text:
            let text = input.text ?? ""
            notes = text
            ideaTitle = input.suggestedTitle ?? String(text.prefix(100))
            ideaDescription = text
        case .file:
            let name = input.fileName ?? "file"
            notes = name
            documentTitle = input.suggestedTitle ?? ""
            selectedEntityType = .document
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

        switch selectedEntityType {
        case .expense:
            saveExpense(car: car, carId: carId)
        case .idea:
            saveIdea(carId: carId)
        case .document:
            saveDocument(carId: carId)
        }
    }

    func cancel() {
        onCancel?()
    }

    // MARK: - Save methods

    private func saveExpense(car: Car, carId: Int64) {
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
        isSaving = false
        onComplete?()
    }

    private func saveIdea(carId: Int64) {
        let trimmedTitle = ideaTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUrl = ideaUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = ideaDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        let idea = Idea(
            carId: carId,
            title: trimmedTitle,
            url: trimmedUrl.isEmpty ? nil : trimmedUrl,
            descriptionText: trimmedDesc.isEmpty ? nil : trimmedDesc
        )

        guard let insertedId = DatabaseManager.shared.ideasRepository?.insertRecord(idea) else {
            logger.error("Failed to insert idea from Share Extension")
            errorMessage = L("share.error.save_failed")
            isSaving = false
            return
        }

        logger.info("Idea created from Share Extension with id: \(insertedId)")
        isSaving = false
        onComplete?()
    }

    private func saveDocument(carId: Int64) {
        guard let input = sharedInput,
              let tempFileURL = input.tempFileURL,
              let fileName = input.fileName else {
            errorMessage = L("share.error.save_failed")
            isSaving = false
            return
        }

        let fileData: Data
        do {
            fileData = try Data(contentsOf: tempFileURL)
        } catch {
            logger.error("Failed to read temp file: \(error.localizedDescription)")
            errorMessage = L("share.error.save_failed")
            isSaving = false
            return
        }

        let fileType = DocumentService.shared.detectFileType(fileName: fileName)
        let trimmedDocumentTitle = documentTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let savedURL = DocumentService.shared.saveFile(data: fileData, fileName: fileName, carId: carId) else {
            logger.error("Failed to save document file from Share Extension")
            errorMessage = L("share.error.save_failed")
            isSaving = false
            return
        }

        let document = CarDocument(
            carId: carId,
            customTitle: trimmedDocumentTitle.isEmpty ? nil : trimmedDocumentTitle,
            fileName: savedURL.lastPathComponent,
            filePath: savedURL.path,
            fileType: fileType,
            fileSize: Int64(fileData.count)
        )

        guard let insertedId = DatabaseManager.shared.documentsRepository?.insertRecord(document) else {
            logger.error("Failed to insert document record from Share Extension")
            DocumentService.shared.deleteFile(at: savedURL.path)
            errorMessage = L("share.error.save_failed")
            isSaving = false
            return
        }

        logger.info("Document created from Share Extension with id: \(insertedId)")
        isSaving = false
        onComplete?()
    }
}
