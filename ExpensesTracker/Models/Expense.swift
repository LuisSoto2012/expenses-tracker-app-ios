import Foundation

struct Expense: Identifiable, Equatable, Codable {
    let id: UUID
    var amount: Double
    var date: Date
    var notes: String?
    var categoryId: UUID
    var isRecurring: Bool
    var recurrenceInterval: RecurrenceInterval?
    var isFixed: Bool?
    
    init(
        id: UUID = UUID(),
        amount: Double,
        date: Date = Date(),
        notes: String? = nil,
        categoryId: UUID,
        isRecurring: Bool = false,
        recurrenceInterval: RecurrenceInterval? = nil,
        isFixed: Bool? = nil
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.notes = notes
        self.categoryId = categoryId
        self.isRecurring = isRecurring
        self.recurrenceInterval = recurrenceInterval
        self.isFixed = isFixed
    }
    
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id &&
               lhs.amount == rhs.amount &&
               lhs.date == rhs.date &&
               lhs.notes == rhs.notes &&
               lhs.categoryId == rhs.categoryId &&
               lhs.isRecurring == rhs.isRecurring &&
               lhs.recurrenceInterval == rhs.recurrenceInterval &&
               lhs.isFixed == rhs.isFixed
    }
}

enum RecurrenceInterval: String, Codable {
    case daily
    case weekly
    case monthly
    case yearly
} 
