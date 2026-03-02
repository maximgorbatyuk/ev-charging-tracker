//
//  IdeasListView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct IdeasListView: SwiftUI.View {

    @StateObject private var viewModel = IdeasViewModel()
    @ObservedObject private var analytics = AnalyticsService.shared

    @SwiftUI.Binding var triggerAdd: Bool

    @State private var showingAddIdea = false
    @State private var ideaToEdit: Idea?
    @State private var ideaToDelete: Idea?
    @State private var ideaToShowDetails: Idea?
    @State private var showingDeleteConfirmation = false

    var body: some SwiftUI.View {
        Group {
            if viewModel.ideas.isEmpty {
                emptyState
            } else {
                ideasList
            }
        }
        .navigationTitle(L("Ideas"))
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            analytics.trackScreen("ideas_list_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .onChange(of: triggerAdd) { _, newValue in
            if newValue {
                showingAddIdea = true
                triggerAdd = false
            }
        }
        .sheet(isPresented: $showingAddIdea) {
            AddIdeaView(onSave: { title, url, description in
                viewModel.addIdea(title: title, url: url, descriptionText: description)
            })
        }
        .sheet(item: $ideaToEdit) { idea in
            AddIdeaView(
                existingIdea: idea,
                onSave: { _, _, _ in },
                onUpdate: { updatedIdea in
                    viewModel.updateIdea(updatedIdea)
                }
            )
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            deleteConfirmationAlert()
        }
        .sheet(item: $ideaToShowDetails) { idea in
            IdeaDetailView(
                idea: idea,
                onEdit: { editIdea in
                    ideaToEdit = editIdea
                },
                onDelete: { deleteIdea in
                    viewModel.deleteIdea(deleteIdea)
                }
            )
        }
    }

    private var emptyState: some SwiftUI.View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 64))
                    .foregroundColor(.gray.opacity(0.5))

                Text(L("No ideas yet"))
                    .font(.title3)
                    .foregroundColor(.gray)

                Text(L("Add your first idea"))
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.9))
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            .multilineTextAlignment(.center)
        }
    }

    private var ideasList: some SwiftUI.View {
        List {
            ForEach(viewModel.ideas) { idea in
                IdeaRowView(idea: idea)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        ideaToShowDetails = idea
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            ideaToDelete = idea
                            showingDeleteConfirmation = true
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }

                        Button {
                            ideaToEdit = idea
                        } label: {
                            Label(L("Edit"), systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }

            Spacer()
                .frame(height: 80)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func deleteConfirmationAlert() -> Alert {
        Alert(
            title: Text(L("Delete idea?")),
            message: Text(L("Delete selected idea? This action cannot be undone.")),
            primaryButton: .destructive(Text(L("Delete"))) {
                if let idea = ideaToDelete {
                    viewModel.deleteIdea(idea)
                }
                ideaToDelete = nil
            },
            secondaryButton: .cancel {
                ideaToDelete = nil
            }
        )
    }
}

struct IdeaRowView: SwiftUI.View {

    let idea: Idea

    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 6) {
            Text(idea.title)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)

            if let host = idea.hostName {
                Label(host, systemImage: "link")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            if let description = idea.descriptionText, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
