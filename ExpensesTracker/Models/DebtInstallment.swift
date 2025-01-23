import Foundation

struct DebtInstallment: Identifiable, Codable {
    var id: String = UUID().uuidString
    var number: Int
    var dueDate: Date
    var amount: Double
    var paidAmount: Double?
    var paidDate: Date?
    var expenseId: UUID?
    
    var isPaid: Bool { paidAmount != nil }
    
    var remainingAmount: Double {
        amount - (paidAmount ?? 0)
    }
} 
