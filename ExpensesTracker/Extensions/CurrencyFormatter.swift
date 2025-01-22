//
//  CurrencyFormatter.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 21/01/25.
//

import Foundation

struct CurrencyFormatter {
    static var usd: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }
    static var pen: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.maximumFractionDigits = 2
        return formatter
    }
}
