import Foundation

struct Debt: Identifiable, Codable {
    var id: UUID
    var name: String
    var totalAmount: Double?
    var numberOfInstallments: Int
    var startDate: Date
    var status: DebtStatus
    var installments: [DebtInstallment]
    var description: String?
    var sharedWithPartner: Bool
    var createdBy: String
    var lastModified: Date
    
    init(id: UUID = UUID(), 
         name: String, 
         totalAmount: Double? = nil,
         numberOfInstallments: Int,
         startDate: Date = Date(),
         description: String? = nil,
         sharedWithPartner: Bool = false) {
        self.id = id
        self.name = name
        self.totalAmount = totalAmount
        self.numberOfInstallments = numberOfInstallments
        self.startDate = startDate
        self.status = .pending
        self.description = description
        self.sharedWithPartner = sharedWithPartner
        self.createdBy = "" // Will be set when saving
        self.lastModified = Date()
        self.installments = []
        
        // Generate installments
        self.generateInstallments()
    }
    
    private mutating func generateInstallments() {
        let calendar = Calendar.current
        var installments: [DebtInstallment] = []
        
        for i in 0..<numberOfInstallments {
            if let dueDate = calendar.date(byAdding: .month, value: i, to: startDate) {
                let installment = DebtInstallment(
                    number: i + 1,
                    dueDate: dueDate,
                    amount: totalAmount.map { $0 / Double(numberOfInstallments) }
                )
                installments.append(installment)
            }
        }
        
        self.installments = installments
    }
    
    var progress: Double {
        let paidInstallments = installments.filter { $0.isPaid }.count
        return Double(paidInstallments) / Double(numberOfInstallments)
    }
    
    var remainingAmount: Double? {
        guard let total = totalAmount else { return nil }
        let paidAmount = installments
            .compactMap { $0.paidAmount }
            .reduce(0, +)
        return total - paidAmount
    }
}

enum DebtStatus: String, Codable {
    case pending = "Pending"
    case paid = "Paid"
} 