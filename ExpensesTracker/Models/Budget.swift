import Foundation

struct Budget: Identifiable, Codable {
    let id: UUID
    var categoryId: UUID
    var amount: Double
    var month: Date // We'll use this to track budgets for different months
    
    init(id: UUID = UUID(), categoryId: UUID, amount: Double, month: Date) {
        self.id = id
        self.categoryId = categoryId
        self.amount = amount
        self.month = month
    }
} 