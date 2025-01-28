import SwiftUI

struct PaymentMethod: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: PaymentMethodType
    var colorHex: String
    var lastFourDigits: String?
    var expiryDate: Date?
    var isDefault: Bool
    
    init(id: UUID = UUID(),
         name: String,
         type: PaymentMethodType,
         colorHex: String = "#007AFF",
         lastFourDigits: String? = nil,
         expiryDate: Date? = nil,
         isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.colorHex = colorHex
        self.lastFourDigits = lastFourDigits
        self.expiryDate = expiryDate
        self.isDefault = isDefault
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

enum PaymentMethodType: String, Codable, CaseIterable {
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case bankAccount = "Bank Account"
    case cash = "Cash"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .creditCard: return "creditcard"
        case .debitCard: return "creditcard.fill"
        case .bankAccount: return "building.columns"
        case .cash: return "banknote"
        case .other: return "square.and.pencil"
        }
    }
} 