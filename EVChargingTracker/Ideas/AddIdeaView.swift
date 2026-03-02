//
//  AddIdeaView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct AddIdeaView: SwiftUI.View {

    let existingIdea: Idea?
    let onSave: (String, String?, String?) -> Void
    let onUpdate: ((Idea) -> Void)?

    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var url: String = ""
    @State private var descriptionText: String = ""
    @State private var alertMessage: String?

    init(
        existingIdea: Idea? = nil,
        onSave: @escaping (String, String?, String?) -> Void,
        onUpdate: ((Idea) -> Void)? = nil
    ) {
        self.existingIdea = existingIdea
        self.onSave = onSave
        self.onUpdate = onUpdate
    }

    private var isEditMode: Bool {
        existingIdea != nil
    }

    var body: some SwiftUI.View {
        NavigationStack {
            Form {
                Section(header: Text(L("Title"))) {
                    TextField(L("idea.title.placeholder"), text: $title)
                }

                Section(header: Text(L("URL"))) {
                    TextField(L("idea.url.placeholder"), text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section(header: Text(L("Description"))) {
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditMode ? L("Edit idea") : L("New idea"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) { save() }
                }
            }
            .alert(L("Error"), isPresented: .constant(alertMessage != nil)) {
                Button(L("OK")) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
            .onAppear {
                if let idea = existingIdea {
                    title = idea.title
                    url = idea.url ?? ""
                    descriptionText = idea.descriptionText ?? ""
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            alertMessage = L("idea.title.required")
            return
        }

        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedUrl.isEmpty {
            guard let parsed = URL(string: trimmedUrl),
                  let scheme = parsed.scheme?.lowercased(),
                  ["http", "https"].contains(scheme) else {
                alertMessage = L("idea.url.invalid")
                return
            }
        }

        if isEditMode, let idea = existingIdea {
            let updated = Idea(
                id: idea.id,
                carId: idea.carId,
                title: trimmedTitle,
                url: trimmedUrl.isEmpty ? nil : trimmedUrl,
                descriptionText: trimmedDescription.isEmpty ? nil : trimmedDescription,
                createdAt: idea.createdAt,
                updatedAt: Date()
            )
            onUpdate?(updated)
        } else {
            onSave(
                trimmedTitle,
                trimmedUrl.isEmpty ? nil : trimmedUrl,
                trimmedDescription.isEmpty ? nil : trimmedDescription
            )
        }

        dismiss()
    }
}
