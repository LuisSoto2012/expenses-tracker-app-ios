//
//  Account.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 31/01/25.
//

import Foundation

struct Account: Identifiable, Codable {
    var id: UUID
    let name: String
    let type: AccountType
    let initialBalance: Double
    var currentBalance: Double
    let currency: String
    let color: String  // For UI customization
    var paymentMethods: [UUID]  // Relación con PaymentMethods (si tienes varios medios de pago vinculados)
    var isDefault: Bool
    
    enum AccountType: String, Codable {
        case checking
        case savings
        case credit
        case cash
    }
    
    init(id: UUID = UUID(),
         name: String,
         balance: Double,
         currency: String,
         paymentMethods: [UUID],
         isDefault: Bool) {
        self.id = id
        self.name = name
        self.initialBalance = balance
        self.currentBalance = balance
        self.currency = currency
        self.paymentMethods = paymentMethods
        self.isDefault = isDefault
        self.type = .checking
        self.color = ""
    }
}

extension Account.AccountType {
    var icon: String {
        switch self {
        case .checking:
            return "creditcard"
        case .savings:
            return "banknote"
        case .credit:
            return "creditcard.fill"
        case .cash:
            return "dollarsign.circle"
        }
    }
}
