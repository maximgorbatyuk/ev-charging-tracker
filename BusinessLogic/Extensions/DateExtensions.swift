//
//  Date+Extensions.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.01.2026.
//

import Foundation

extension Date {
    /// Formats the date using a custom date format string
    /// - Parameter format: The date format string (e.g., "yyyy-MM-dd", "MMM dd, yyyy")
    /// - Returns: A formatted string representation of the date
    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
