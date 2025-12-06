//
//  FilterButtonItem.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 06.12.2025.
//

import Foundation

class FilterButtonItem: ObservableObject {
    let id: UUID = UUID()
    let title: String
    var isSelected = false
    private let innerAction: () -> Void

    init(
        title: String,
        innerAction: @escaping () -> Void,
        isSelected: Bool = false) {
        self.title = title
        self.innerAction = innerAction
        self.isSelected = isSelected
    }

    func action() {
        innerAction()
        self.isSelected = true
    }

    func deselect() {
        self.isSelected = false
    }
}
