//
//  Transaction.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 1/02/25.
//

import Foundation

enum TransactionType: String, Codable {
    case expense
    case income
    case debt
}

struct Transaction: Identifiable, Codable {
    var id: UUID  // Cambiado a UUID para mantener la consistencia
    var expenseId: UUID?  // Optional, for linking to existing expenses
    var accountId: UUID
    var amount: Double
    var type: TransactionType
    var date: Date
    var description: String
    var category: UUID?  // Optional, same as in expenses
    
    var isIncoming: Bool {
        return type == .income
    }
    
    // Inicializador
    init(id: UUID = UUID(),
         expenseId: UUID? = nil,
         accountId: UUID,
         amount: Double,
         type: TransactionType,
         date: Date,
         description: String,
         category: UUID? = nil) {
        self.id = id
        self.expenseId = expenseId
        self.accountId = accountId
        self.amount = amount
        self.type = type
        self.date = date
        self.description = description
        self.category = category
    }
}
