//
//  Transaction.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 1/02/25.
//

import Foundation

struct Transaction: Identifiable, Codable {
    var id: UUID
    var amount: Double  // Negativo para gastos, positivo para ingresos
    var date: Date
    var description: String
    var paymentMethodId: UUID
    var accountId: UUID
    
    init(id: UUID = UUID(),
         amount: Double,
         date: Date,
         description: String,
         paymentMethodId: UUID,
         accountId: UUID) {
        self.id = id
        self.amount = amount
        self.date = date
        self.description = description
        self.paymentMethodId = paymentMethodId
        self.accountId = accountId
    }
}
