import SwiftUI

struct PaymentMethod: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: PaymentMethodType
    var colorHexPrimary: String
    var colorHexSecondary: String
    var gradientDirection: GradientDirection
    var lastFourDigits: String?
    var expiryDate: Date?
    var isDefault: Bool
    
    init(id: UUID = UUID(),
         name: String,
         type: PaymentMethodType,
         colorHexPrimary: String = "#007AFF",
         colorHexSecondary: String = "#34C759",
         gradientDirection: GradientDirection = .topLeftToBottomRight,
         lastFourDigits: String? = nil,
         expiryDate: Date? = nil,
         isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.colorHexPrimary = colorHexPrimary
        self.colorHexSecondary = colorHexSecondary
        self.gradientDirection = gradientDirection
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
    
    var gradientStart: UnitPoint {
        gradientDirection.startPoint
    }
    
    var gradientEnd: UnitPoint {
        gradientDirection.endPoint
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

enum GradientDirection: String, Codable, CaseIterable {
    case topLeftToBottomRight = "Top Left → Bottom Right"
    case topRightToBottomLeft = "Top Right → Bottom Left"
    case bottomLeftToTopRight = "Bottom Left → Top Right"
    case bottomRightToTopLeft = "Bottom Right → Top Left"
    case leftToRight = "Left → Right"
    case rightToLeft = "Right → Left"
    case topToBottom = "Top → Bottom"
    case bottomToTop = "Bottom → Top"
    
    var startPoint: UnitPoint {
        switch self {
        case .topLeftToBottomRight: return .topLeading
        case .topRightToBottomLeft: return .topTrailing
        case .bottomLeftToTopRight: return .bottomLeading
        case .bottomRightToTopLeft: return .bottomTrailing
        case .leftToRight: return .leading
        case .rightToLeft: return .trailing
        case .topToBottom: return .top
        case .bottomToTop: return .bottom
        }
    }
    
    var endPoint: UnitPoint {
        switch self {
        case .topLeftToBottomRight: return .bottomTrailing
        case .topRightToBottomLeft: return .bottomLeading
        case .bottomLeftToTopRight: return .topTrailing
        case .bottomRightToTopLeft: return .topLeading
        case .leftToRight: return .trailing
        case .rightToLeft: return .leading
        case .topToBottom: return .bottom
        case .bottomToTop: return .top
        }
    }
}
