//
//  CurrencyFormatter.swift
//  Event Budgeter
//

import Foundation

extension Decimal {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: self as NSDecimalNumber) ?? "$\(self)"
    }
}
