//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 21/07/21.
//

import StoreKit

extension SKProduct {
    
    var localizedPrice: String? {
        return priceFormatter(locale: priceLocale).string(from: price)
    }
    
    private func priceFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        return formatter
    }
    
}
