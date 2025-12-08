//
//  AlertData.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 06.12.2025.
//

import Foundation

class ConfirmationData: ObservableObject {

    static let empty = ConfirmationData(
        title: "",
        message: "",
        action: {},
        showDialog: false)
    
    @Published var title: String
    @Published var message: String
    @Published var confirmButtonTitle: String = "Confirm"
    @Published var cancelButtonTitle: String = "Cancel"
    @Published var action: () -> Void
    @Published var showDialog = true
    
    init(
        title: String,
        message: String,
        action: @escaping () -> Void,
        showDialog: Bool = true,
        confirmButtonTitle: String = "Confirm",
        cancelButtonTitle: String = "Cancel") {
        self.title = title
        self.message = message
        self.action = action
        self.showDialog = showDialog
        self.confirmButtonTitle = confirmButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
    }

    func executeAction() {
        action()
    }
}
