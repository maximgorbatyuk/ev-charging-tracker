//
//  RuntimeError.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.12.2025.
//

import Foundation

struct RuntimeError: LocalizedError {
    let description: String

    init(_ description: String) {
        self.description = description
    }

    var errorDescription: String? {
        description
    }
}
