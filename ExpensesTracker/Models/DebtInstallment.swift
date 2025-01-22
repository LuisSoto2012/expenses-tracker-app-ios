import Foundation

struct DebtInstallment: Identifiable, Codable {
    var id: UUID = UUID()
    var number: Int
    var dueDate: Date
    var amount: Double?
    var paidAmount: Double?
    var paidDate: Date?
    var isPaid: Bool { paidAmount != nil }
    
    var remainingAmount: Double? {
        guard let amount = amount else { return nil }
        return amount - (paidAmount ?? 0)
    }
} 