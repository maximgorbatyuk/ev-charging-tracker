//
//  ShareFormView.swift
//  ShareExtension
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct ShareFormView: SwiftUI.View {

    @ObservedObject var viewModel: ShareFormViewModel

    var body: some SwiftUI.View {
        NavigationStack {
            Group {
                if viewModel.hasCars {
                    formContent
                } else {
                    noCarsView
                }
            }
            .navigationTitle(L("share.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("share.cancel")) {
                        viewModel.cancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("share.save")) {
                        viewModel.save()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

    // MARK: - Form content

    private var formContent: some SwiftUI.View {
        Form {
            // Content preview
            if let input = viewModel.sharedInput {
                Section(header: Text(L("share.section.content"))) {
                    contentPreview(input: input)
                }
            }

            // Car picker
            Section(header: Text(L("share.section.car"))) {
                Picker(L("share.car_picker"), selection: $viewModel.selectedCarId) {
                    Text(L("share.car_picker.placeholder"))
                        .tag(nil as Int64?)

                    ForEach(viewModel.cars) { car in
                        Text(car.name)
                            .tag(car.id as Int64?)
                    }
                }
            }

            // Expense type
            Section(header: Text(L("share.section.type"))) {
                Picker(L("share.type_picker"), selection: $viewModel.selectedExpenseType) {
                    ForEach(ExpenseType.allCases, id: \.self) { type in
                        Text(expenseTypeDisplayName(type))
                            .tag(type)
                    }
                }
            }

            // Notes
            Section(header: Text(L("share.section.notes"))) {
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 100)
            }

            // Error
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Content preview

    @ViewBuilder
    private func contentPreview(input: SharedInput) -> some SwiftUI.View {
        switch input.kind {
        case .link:
            if let url = input.url {
                VStack(alignment: .leading, spacing: 4) {
                    Label(url.host ?? url.absoluteString, systemImage: "link")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let title = input.suggestedTitle, title != url.host {
                        Text(title)
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        case .text:
            if let text = input.text {
                Text(text.prefix(200) + (text.count > 200 ? "..." : ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            }
        }
    }

    // MARK: - No cars view

    private var noCarsView: some SwiftUI.View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(L("share.no_cars.title"))
                .font(.headline)
            Text(L("share.no_cars.message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func expenseTypeDisplayName(_ type: ExpenseType) -> String {
        switch type {
        case .charging:
            return L("expense.filter.charging")
        case .maintenance:
            return L("expense.filter.maintenance")
        case .repair:
            return L("expense.filter.repair")
        case .carwash:
            return L("expense.filter.carwash")
        case .other:
            return L("expense.filter.other")
        }
    }
}
