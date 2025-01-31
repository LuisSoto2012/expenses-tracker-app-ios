import SwiftUI

struct PaymentMethod: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: PaymentMethodType
    var colorHexPrimary: String
    var colorHexSecondary: String
    var lastFourDigits: String?
    var expiryDate: Date?
    var isDefault: Bool
    
    init(id: UUID = UUID(),
         name: String,
         type: PaymentMethodType,
         colorHexPrimary: String = "#007AFF",
         colorHexSecondary: String = "#34C759",
         lastFourDigits: String? = nil,
         expiryDate: Date? = nil,
         isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.colorHexPrimary = colorHexPrimary
        self.colorHexSecondary = colorHexSecondary
        self.lastFourDigits = lastFourDigits
        self.expiryDate = expiryDate
        self.isDefault = isDefault
    }
    
    var colorPrimary: Color {
        Color(hex: colorHexPrimary) ?? .blue
    }
    
    var colorSecondary: Color {
        Color(hex: colorHexSecondary) ?? .green
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
