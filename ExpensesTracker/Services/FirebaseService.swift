import Foundation
import FirebaseFirestore

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
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
    
    func saveExpense(_ expense: Expense) {
        do {
            try db.collection("expenses")
                .document(expense.id.uuidString)
                .setData(from: expense)
        } catch {
            print("Error saving expense: \(error.localizedDescription)")
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
}
