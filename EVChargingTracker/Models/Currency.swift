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
    case trl = "₺"
    case aed = "Dh"
    case sar = "SR"
    case gbp = "£"
    case jpy = "¥"
    case rub = "₽"

    var displayName: String {
        switch self {
            case .usd: return "🇺🇸 US Dollar"
            case .kzt: return "🇰🇿 Kazakhstani Tenge"
            case .eur: return "🇪🇺 Euro"
            case .trl: return "🇹🇷 Turkish Lira"
            case .aed: return "🇦🇪 UAE Dirham"
            case .sar: return "🇸🇦 Saudi Riyal"
            case .gbp: return "🇬🇧 British Pound"
            case .jpy: return "🇯🇵 Japanese Yen"
            case .rub: return "🇷🇺 Russian Ruble"

            @unknown default:
                return "Unknown Currency"
        }
    }
}
