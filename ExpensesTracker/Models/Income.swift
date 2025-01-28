import Foundation

struct Income: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: IncomeType
    var amount: Double?
    var frequency: IncomeFrequency
    var paymentMethod: UUID?  // Reference to PaymentMethod
    var createdAt: Date
    
    init(id: UUID = UUID(), 
         name: String, 
         type: IncomeType, 
         amount: Double? = nil, 
         frequency: IncomeFrequency,
         paymentMethod: UUID? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.amount = amount
        self.frequency = frequency
        self.paymentMethod = paymentMethod
        self.createdAt = Date()
    }
}

enum IncomeType: String, Codable, CaseIterable {
    case fixed = "Fixed"
    case variable = "Variable"
}

enum IncomeFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biWeekly = "Bi-Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var multiplierForMonthly: Double {
        switch self {
        case .weekly: return 4.33
        case .biWeekly: return 2.17
        case .monthly: return 1.0
        case .yearly: return 1/12.0
        }
    }
} 