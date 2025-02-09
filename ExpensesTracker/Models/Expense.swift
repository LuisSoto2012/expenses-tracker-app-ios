import Foundation

struct Expense: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var date: Date
    var notes: String?
    var categoryId: UUID
    var isRecurring: Bool
    var recurrenceInterval: RecurrenceInterval?
    var isFixed: Bool?
    var isPaid: Bool?
    var paymentMethodId: UUID?
    var isAutomaticPayment: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        date: Date = Date(),
        notes: String? = nil,
        categoryId: UUID,
        isRecurring: Bool = false,
        recurrenceInterval: RecurrenceInterval? = nil,
        isFixed: Bool? = nil,
        paymentMethodId: UUID? = nil,
        isAutomaticPayment: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.date = date
        self.notes = notes
        self.categoryId = categoryId
        self.isRecurring = isRecurring
        self.recurrenceInterval = recurrenceInterval
        self.isFixed = isFixed
        self.paymentMethodId = paymentMethodId
        self.isAutomaticPayment = isAutomaticPayment
    }
    
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
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
    case daily = "Diario"
    case weekly = "Semanal"
    case monthly = "Mensual"
    case yearly = "Anual"
} 
