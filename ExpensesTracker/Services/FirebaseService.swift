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
    
    func syncTransactions(completion: @escaping ([Transaction]) -> Void) {
        let listener = db.collection("transactions")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching transactions: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let transactions = documents.compactMap { document -> Transaction? in
                    try? document.data(as: Transaction.self)
                }
                completion(transactions)
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
    
    // MARK: - Debt Management
    func syncDebts(completion: @escaping ([Debt]) -> Void) {
        let listener = db.collection("debts")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching debts: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let debts = documents.compactMap { document -> Debt? in
                    try? document.data(as: Debt.self)
                }
                completion(debts)
            }
        listeners.append(listener)
    }
    
    func saveDebt(_ debt: Debt) {
        do {
            try db.collection("debts")
                .document(debt.id.uuidString)
                .setData(from: debt)
        } catch {
            print("Error saving debt: \(error.localizedDescription)")
        }
    }
    
    func updateDebt(_ debt: Debt) {
        do {
            try db.collection("debts")
                .document(debt.id.uuidString)
                .setData(from: debt)
        } catch {
            print("Error updating debt: \(error.localizedDescription)")
        }
    }
    
    func deleteDebt(id: UUID) {
        db.collection("debts")
            .document(id.uuidString)
            .delete { error in
                if let error = error {
                    print("Error deleting debt: \(error.localizedDescription)")
                }
            }
    }
    
    // Incomes
    func syncIncomes(completion: @escaping ([Income]) -> Void) {
        let listener = db.collection("incomes")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching incomes: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let incomes = documents.compactMap { document -> Income? in
                    try? document.data(as: Income.self)
                }
                completion(incomes)
            }
        listeners.append(listener)
    }
    
    func syncPaymentMethods(completion: @escaping ([PaymentMethod]) -> Void) {
        let listener = db.collection("paymentMethods")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching payment methods: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let paymentMethods = documents.compactMap { document -> PaymentMethod? in
                    try? document.data(as: PaymentMethod.self)
                }
                completion(paymentMethods)
            }
        listeners.append(listener)
    }
    
    func saveIncome(_ income: Income) {
        do {
            try db.collection("incomes")
                .document(income.id.uuidString)
                .setData(from: income)
        } catch {
            print("Error saving income: \(error.localizedDescription)")
        }
    }
    
    func savePaymentMethod(_ paymentMethod: PaymentMethod) {
        do {
            try db.collection("paymentMethods")
                .document(paymentMethod.id.uuidString)
                .setData(from: paymentMethod)
        } catch {
            print("Error saving payment method: \(error.localizedDescription)")
        }
    }
    
    func deleteIncome(id: UUID) {
        db.collection("incomes")
            .document(id.uuidString)
            .delete()
    }
    
    func deletePaymentMethod(id: UUID) {
        db.collection("paymentMethods")
            .document(id.uuidString)
            .delete()
    }
    
    // MARK: - Account Management

    // Sincronizar cuentas desde Firebase
    func syncAccounts(completion: @escaping ([Account]) -> Void) {       
        db.collection("accounts")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching accounts: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let accounts = documents.compactMap { document -> Account? in
                    try? document.data(as: Account.self)
                }
                completion(accounts)
            }
    }

    // Guardar una cuenta en Firebase (agregar o actualizar)
    func saveAccount(_ account: Account) {
        do {
            try db.collection("accounts")
                .document(account.id.uuidString)
                .setData(from: account)
        } catch {
            print("Error saving account: \(error.localizedDescription)")
        }
    }

    // Eliminar una cuenta en Firebase
    func deleteAccount(id: UUID) {
        db.collection("accounts")
            .document(id.uuidString)
            .delete()
    }

    // Actualizar una cuenta en Firebase (similar a save, pero es una actualización explícita)
    func updateAccount(_ account: Account) {
        saveAccount(account)
    }
    
    func deleteAllCollectionsExceptCategories() {
        // Eliminar documentos de todas las colecciones excepto "categories"
        let collectionsToDelete = ["expenses", "budgets", "debts", "incomes", "paymentMethods", "accounts"]
        
        // Iterar sobre las colecciones a eliminar
        for collectionName in collectionsToDelete {
            db.collection(collectionName).getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents from \(collectionName): \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in \(collectionName).")
                    return
                }
                
                // Eliminar cada documento de la colección
                for document in documents {
                    document.reference.delete { error in
                        if let error = error {
                            print("Error deleting document \(document.documentID) from \(collectionName): \(error.localizedDescription)")
                        } else {
                            print("Document \(document.documentID) deleted from \(collectionName).")
                        }
                    }
                }
            }
        }
    }
    
    func deleteCollection(collectionName: String) {
        db.collection(collectionName).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching documents from \(collectionName): \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found in \(collectionName).")
                return
            }
            
            // Eliminar cada documento de la colección
            for document in documents {
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting document \(document.documentID) from \(collectionName): \(error.localizedDescription)")
                    } else {
                        print("Document \(document.documentID) deleted from \(collectionName).")
                    }
                }
            }
        }
    }
    
    // Transactions
    
    // Guardar una transacción en Firebase
    func saveTransaction(_ transaction: Transaction) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try db.collection("users").document(userId).collection("transactions")
                .document(transaction.id.uuidString)
                .setData(from: transaction)
        } catch {
            print("Error saving transaction: \(error.localizedDescription)")
        }
    }

    // Obtener todas las transacciones de una cuenta
    func fetchTransactions(for accountId: UUID, completion: @escaping ([Transaction]) -> Void) {
        db.collection("transactions")
            .whereField("accountId", isEqualTo: accountId.uuidString)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching transactions: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let transactions = documents.compactMap { document -> Transaction? in
                    try? document.data(as: Transaction.self)
                }
                completion(transactions)
            }
    }
}
