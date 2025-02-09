//
//  Account.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 31/01/25.
//

import Foundation

struct Account: Identifiable, Codable {
   var id: UUID
   var name: String
   var initialBalance: Double
   var balance: Double
   var currency: String
   var paymentMethods: [UUID]  // Relación con PaymentMethods (si tienes varios medios de pago vinculados)
   var isDefault: Bool
    
    init(id: UUID = UUID(),
         name: String,
         balance: Double,
         currency: String,
         paymentMethods: [UUID],
         isDefault: Bool) {
        self.id = id
        self.name = name
        self.initialBalance = balance
        self.balance = balance
        self.currency = currency
        self.paymentMethods = paymentMethods
        self.isDefault = isDefault
    }
}
