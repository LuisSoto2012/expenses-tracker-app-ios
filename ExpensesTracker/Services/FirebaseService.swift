import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    init() {} // Make initializer private for singleton pattern
    
    func syncExpenses(completion: @escaping ([Expense]) -> Void) {
        let listener = db.collection("expenses")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching expenses: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let expenses = documents.compactMap { document -> Expense? in
                    try? document.data(as: Expense.self)
                }
                completion(expenses)
            }
        listeners.append(listener)
    }
    
    func syncCategories(completion: @escaping ([Category]) -> Void) {
        let listener = db.collection("categories")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching categories: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let categories = documents.compactMap { document -> Category? in
                    try? document.data(as: Category.self)
                }
                completion(categories)
            }
        listeners.append(listener)
    }
    
    func syncBudgets(completion: @escaping ([Budget]) -> Void) {
        let listener = db.collection("budgets")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching budgets: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let budgets = documents.compactMap { document -> Budget? in
                    try? document.data(as: Budget.self)
                }
                completion(budgets)
            }
        listeners.append(listener)
    }
    
    func saveExpense(_ expense: Expense) -> UUID? {
        do {
            try db.collection("expenses")
                .document(expense.id.uuidString)
                .setData(from: expense)
            return expense.id
        } catch {
            print("Error saving expense: \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveCategory(_ category: Category) {
        do {
            try db.collection("categories")
                .document(category.id.uuidString)
                .setData(from: category)
        } catch {
            print("Error saving category: \(error.localizedDescription)")
        }
    }
    
    func getCategoryByName(_ name: String, completion: @escaping (Category?) -> Void) {
        db.collection("categories")
            .whereField("name", isEqualTo: name)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching category by name: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(nil) // No category found with the given name
                    return
                }
                
                let category = try? document.data(as: Category.self)
                completion(category)
            }
    }
    
    func saveBudget(_ budget: Budget) {
        do {
            try db.collection("budgets")
                .document(budget.id.uuidString)
                .setData(from: budget)
        } catch {
            print("Error saving budget: \(error.localizedDescription)")
        }
    }
    
    func deleteExpense(id: UUID) {
        db.collection("expenses")
            .document(id.uuidString)
            .delete()
    }
    
    func deleteCategory(id: UUID) {
        db.collection("categories")
            .document(id.uuidString)
            .delete()
    }
    
    func deleteBudget(id: UUID) {
        db.collection("budgets")
            .document(id.uuidString)
            .delete()
    }
    
    func cleanup() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Debt Management
    func observeDebts(completion: @escaping ([Debt]) -> Void) {
        let listener = db.collection("debts")
            .order(by: "creationDate", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching debts: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                // Agregar una anotación de tipo explícita a `debts`
                let debts: [Debt] = documents.compactMap { document -> Debt? in
                    guard let firebaseDebt = try? document.data(as: Debt.FirebaseDebt.self) else { return nil }
                    return firebaseDebt.toDebt()
                }
                completion(debts)
            }
        listeners.append(listener)
    }

    func addDebt(_ debt: Debt) async throws {
        var newDebt = debt
        newDebt.createdBy = Auth.auth().currentUser?.uid ?? ""
        newDebt.creationDate = Date()
        try db.collection("debts").document(newDebt.id.uuidString).setData(from: newDebt)
    }

    func updateDebt(_ debt: Debt) async throws {
        let id = debt.id.uuidString
        var updatedDebt = debt
        updatedDebt.lastModified = Date()
        try db.collection("debts").document(id).setData(from: updatedDebt)
    }

    func deleteDebt(_ debt: Debt) async throws {
        let id = debt.id.uuidString
        try await db.collection("debts").document(id).delete()
    }
}

// Add this extension to handle Firebase-specific debt mapping
private extension Debt {
    // Para Firebase storage
    struct FirebaseDebt: Codable {
        @DocumentID var id: String? // ID en Firebase es un String
        var name: String
        var totalAmount: Double
        var numberOfInstallments: Int
        var startDate: Date
        var status: DebtStatus
        var installments: [DebtInstallment]
        var description: String?
        var sharedWithPartner: Bool
        var createdBy: String
        var creationDate: Date
        var lastModified: Date?

        // Convertir de Debt a FirebaseDebt
        init(from debt: Debt) {
            self.id = debt.id.uuidString // Convertir el UUID a String
            self.name = debt.name
            self.totalAmount = debt.totalAmount
            self.numberOfInstallments = debt.numberOfInstallments
            self.startDate = debt.startDate
            self.status = debt.status
            self.installments = debt.installments
            self.description = debt.description
            self.sharedWithPartner = debt.sharedWithPartner
            self.createdBy = debt.createdBy
            self.lastModified = nil
            self.creationDate = Date()
        }

        // Convertir de FirebaseDebt a Debt
        func toDebt() -> Debt {
            var debt = Debt(
                id: UUID(uuidString: id ?? "") ?? UUID(), // Convertir String a UUID, o generar uno nuevo si es nil
                name: name,
                totalAmount: totalAmount,
                numberOfInstallments: numberOfInstallments,
                startDate: startDate,
                description: description,
                sharedWithPartner: sharedWithPartner
            )
            debt.status = status
            debt.installments = installments
            debt.createdBy = createdBy
            debt.creationDate = creationDate
            debt.lastModified = lastModified
            return debt
        }
    }
}
