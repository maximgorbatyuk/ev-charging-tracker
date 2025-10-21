//
//  Currency.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

enum Currency: String, CaseIterable, Codable {
    case usd = "$"
    case kzt = "₸"
    case eur = "€"
    case aed = "Dh"
    case sar = "SR"
    case gbp = "£"
    case jpy = "¥"
    case rub = "₽"
}
