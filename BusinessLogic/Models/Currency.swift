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
    case byn = "Br"
    case uah = "₴"
    case rub = "₽"
    case trl = "₺"
    case aed = "Dh"
    case sar = "SR"
    case gbp = "£"
    case jpy = "¥"
    case inr = "₹"

    var shortName: String {
        switch self {
            case .usd: return "🇺🇸 USD"
            case .kzt: return "🇰🇿 KZT"
            case .eur: return "🇪🇺 EUR"
            case .trl: return "🇹🇷 TRY"
            case .aed: return "🇦🇪 AED"
            case .sar: return "🇸🇦 SAR"
            case .gbp: return "🇬🇧 GBP"
            case .jpy: return "🇯🇵 JPY"
            case .rub: return "🇷🇺 RUB"
            case .byn: return "🇧🇾 BYN"
            case .uah: return "🇺🇦 UAH"
            case .inr: return "🇮🇳 INR"

            @unknown default:
                return "Unknown Currency"
        }
    }

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
            case .byn: return "🇧🇾 Belarusian Ruble"
            case .uah: return "🇺🇦 Ukrainian Hryvnia"
            case .inr: return "🇮🇳 Indian Rupee"

            @unknown default:
                return "Unknown Currency"
        }
    }
}
