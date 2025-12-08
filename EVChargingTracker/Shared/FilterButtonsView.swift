//
//  FilterButtonsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 06.12.2025.
//

import SwiftUI
import Foundation

class FilterButtonItem: ObservableObject {
    let id: UUID = UUID()
    let title: String

    @Published var customColor: Color? = nil
    @Published var isSelected = false
    private let innerAction: () -> Void

    init(
        title: String,
        innerAction: @escaping () -> Void,
        customColor: Color? = nil,
        isSelected: Bool = false) {
        self.title = title
        self.innerAction = innerAction
        self.isSelected = isSelected
        self.customColor = customColor
    }

    func action() {
        innerAction()
        self.isSelected = true
    }

    func deselect() {
        self.isSelected = false
    }
}

class FilterButtonsViewModel: ObservableObject {
    @Published var filterButtons: [FilterButtonItem]

    init(_ filterButtons: [FilterButtonItem]) {
        self.filterButtons = filterButtons
    }

    func executeButtonAction(_ button: FilterButtonItem) {
        filterButtons.forEach { $0.deselect() }
        button.action()
    }
}

struct FilterButtonsView: SwiftUICore.View {

    let cornerRadius: CGFloat = 6.0

    @State var viewModel: FilterButtonsViewModel
    @Environment(\.colorScheme) var colorScheme
    
    init(filterButtons: [FilterButtonItem]) {
        viewModel = FilterButtonsViewModel(filterButtons)
    }

    var body: some SwiftUICore.View {
        HStack(spacing: 8) {
            ForEach(viewModel.filterButtons, id: \.id) { button in

                Button(action: {
                    viewModel.executeButtonAction(button)
                }) {
                    Text(button.title)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.vertical, 12)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .animation(.easeInOut, value: button.isSelected)
                .background {
                    if (button.customColor == nil) {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(button.isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(button.isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(button.customColor!.opacity(0.2))
                            .brightness(button.isSelected ? -0.2 : 0.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(
                                        button.customColor!.opacity(0.3),
                                        lineWidth: button.isSelected
                                            ? 3
                                            : 1))
                    }
                }
            }
        }
    }
}
