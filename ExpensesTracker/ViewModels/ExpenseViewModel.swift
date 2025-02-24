import SwiftUI
import FirebaseAuth
import Combine

class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var categories: [Category] = []
    @Published var budgets: [Budget] = []
    @Published var totalMonthlyExpenses: Double = 0
    @Published var isLoading = false
    @Published var needsRefresh: Bool = false
    
    private let firebaseService = FirebaseService()
    private let accountViewModel: AccountViewModel
    
    init(accountViewModel: AccountViewModel) {
        self.accountViewModel = accountViewModel
        setupDataSync()
        
        // Configurar timer para revisar pagos automáticos diariamente
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.checkAutomaticPayments()
        }
        
        // Revisar pagos automáticos al iniciar
        checkAutomaticPayments()
    }
    
    private func setupDataSync() {
        isLoading = true
        
        // Sync expenses
        firebaseService.syncExpenses { [weak self] expenses in
            self?.expenses = expenses
            self?.calculateTotalMonthlyExpenses()
            self?.isLoading = false
        }
        
        // Sync categories
        firebaseService.syncCategories { [weak self] categories in
            if categories.isEmpty {
                // If no categories exist, create defaults
                Category.defaults.forEach { category in
                    self?.addCategory(category)
                }
            } else {
                self?.categories = categories
            }
        }
        
        // Sync budgets
        firebaseService.syncBudgets { [weak self] budgets in
            self?.budgets = budgets
        }
    }
    
    // MARK: - Expense Methods
    
    func addExpense(_ expense: Expense) {
        // Save the expense
        firebaseService.saveExpense(expense)
        
        // Get the account associated with the payment method
        if let paymentMethodId = expense.paymentMethodId,
           let account = accountViewModel.accounts.first(where: { account in
               account.paymentMethods.contains(paymentMethodId)
           }) {
            
            // Create and save the transaction directly
            let transaction = Transaction(
                id: UUID(),
                expenseId: expense.id,
                accountId: account.id,
                amount: expense.amount,
                type: expense.isRecurring ? .debt : .expense,
                date: expense.date,
                description: expense.name,
                category: expense.categoryId
            )
            
            // Save transaction directly to Firebase
            firebaseService.saveTransaction(transaction)
        } else {
            // If no account found for payment method, use default account
            accountViewModel.registerExpense(expense)
        }
    }
    
    func addRecurringExpense(_ expense: Expense, endDate: Date) {
        guard let recurrenceInterval = expense.recurrenceInterval else { return }
            
        var currentDate = expense.date
        var expenses: [Expense] = []
        let today = Date()
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            var newExpense = Expense(
                id: UUID(),
                name: expense.name,
                amount: expense.amount,
                date: currentDate,
                notes: expense.notes,
                categoryId: expense.categoryId,
                isRecurring: expense.isRecurring,
                recurrenceInterval: expense.recurrenceInterval,
                isFixed: expense.isFixed,
                isAutomaticPayment: expense.isAutomaticPayment
            )
            
            // Marcar como pagado si tiene pago automático y la fecha es hoy
            if expense.isAutomaticPayment && calendar.isDate(currentDate, inSameDayAs: today) {
                newExpense.isPaid = true
            }
            
            expenses.append(newExpense)
            
            // Increment currentDate based on the recurrence interval
            switch recurrenceInterval {
            case .daily:
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .weekly:
                currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case .monthly:
                currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            case .yearly:
                currentDate = Calendar.current.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        // Save all expenses to Firestore
        for expense in expenses {
            firebaseService.saveExpense(expense)
        }
    }
    
    func updateExpense(_ expense: Expense, newAmount: Double) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        
        // Crear una copia del gasto con la nueva cantidad
        var updatedExpense = expenses[index]
        updatedExpense.amount = newAmount
        
        // Guardar los cambios en Firebase
        firebaseService.saveExpense(updatedExpense)
        
        // Actualizar la lista local de gastos
        expenses[index] = updatedExpense
        
        // Recalcular el total mensual de gastos (si aplica)
        calculateTotalMonthlyExpenses()
    }
        
    func deleteExpense(_ expense: Expense) {
        firebaseService.deleteExpense(id: expense.id)
    }
    
    func getRecentExpenses() -> [Expense] {
        return expenses.filter { expense in
            if expense.isRecurring {
                return expense.isPaid ?? false // Solo mostrar recurrentes si están pagadas
            } else {
                return true // Mostrar todos los gastos no recurrentes
            }
        }
        .sorted { $0.date > $1.date } // Ordenar por fecha descendente
    }
    
    func reloadExpenses() {
        isLoading = true

        firebaseService.syncExpenses { [weak self] expenses in
            DispatchQueue.main.async {
                self?.expenses = expenses
                self?.calculateTotalMonthlyExpenses()
                self?.isLoading = false
                self?.needsRefresh.toggle()
            }
        }
    }
    
    // MARK: - Category Methods
    
    func addCategory(_ category: Category) {
        firebaseService.saveCategory(category)
    }
    
    func updateCategory(_ category: Category) {
        firebaseService.saveCategory(category)
    }
    
    func deleteCategory(_ category: Category) {
        firebaseService.deleteCategory(id: category.id)
    }
    
    func deleteCategories(at indexSet: IndexSet) {
        // Don't allow deletion if category is in use
        let categoriesToDelete = indexSet.map { categories[$0] }
        let unusedCategories = categoriesToDelete.filter { category in
            !expenses.contains { $0.categoryId == category.id }
        }
        
        // Delete each unused category
        for category in unusedCategories {
            deleteCategory(category)
        }
    }
    
    // MARK: - Budget Methods
    
    func getBudget(for categoryId: UUID, month: Date) -> Budget? {
        let calendar = Calendar.current
        return budgets.first { budget in
            calendar.isDate(budget.month, equalTo: month, toGranularity: .month) &&
            budget.categoryId == categoryId
        }
    }

    func setBudget(_ amount: Double, for categoryId: UUID, month: Date) {
        if let existingBudget = getBudget(for: categoryId, month: month) {
            var updatedBudget = existingBudget
            updatedBudget.amount = amount
            firebaseService.saveBudget(updatedBudget)
        } else {
            let newBudget = Budget(categoryId: categoryId, amount: amount, month: month)
            firebaseService.saveBudget(newBudget)
        }
    }

    func deleteBudget(_ budget: Budget) {
        firebaseService.deleteBudget(id: budget.id)
    }
    
    func removeBudget(for categoryId: UUID, month: Date) {
        if let budget = getBudget(for: categoryId, month: month) {
            deleteBudget(budget)
        }
    }
    
    // MARK: - Helper Methods
    
    func getFilteredExpenses(month: Date, categoryId: UUID?, isRecurring: Bool = false) -> [Expense] {
        let calendar = Calendar.current
        let monthComponent = calendar.component(.month, from: month)
        let yearComponent = calendar.component(.year, from: month)
        
        return expenses.filter { expense in
            let expenseMonth = calendar.component(.month, from: expense.date)
            let expenseYear = calendar.component(.year, from: expense.date)
            
            let monthMatches = expenseMonth == monthComponent && expenseYear == yearComponent
            let categoryMatches = categoryId == nil || expense.categoryId == categoryId
            let recurringMatches = isRecurring == expense.isRecurring
            
            return monthMatches && categoryMatches && recurringMatches
        }
        .sorted { $0.date > $1.date }
    }
    
    func getFilteredExpenses(day: Date, categoryId: UUID?) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter { expense in
            let isSameDay = calendar.isDate(expense.date, inSameDayAs: day)
            let matchesCategory = categoryId == nil || expense.categoryId == categoryId
            return matchesCategory && isSameDay
        }
    }
    
    func getBudgetProgress(for categoryId: UUID, month: Date) -> Double {
        guard let budget = getBudget(for: categoryId, month: month) else { return 0 }
        let spending = getMonthlyExpensesByCategory(for: month)
            .first { $0.0.id == categoryId }?.1 ?? 0
        return spending / budget.amount
    }
    
    func getMonthlyExpensesByCategory(for date: Date) -> [(Category, Double)] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        var categoryTotals: [UUID: Double] = [:]
        
        expenses.forEach { expense in
            let expenseMonth = calendar.component(.month, from: expense.date)
            let expenseYear = calendar.component(.year, from: expense.date)
            
            // Considerar los montos solo si no es recurrente o si es recurrente y está pagado
            if expenseMonth == month && expenseYear == year {
                if !expense.isRecurring || (expense.isRecurring && (expense.isPaid ?? false)) {
                    categoryTotals[expense.categoryId, default: 0] += expense.amount
                }
            }
        }
        
        return categories.compactMap { category in
            guard let total = categoryTotals[category.id] else { return nil }
            return (category, total)
        }
        .sorted { $0.1 > $1.1 }
    }
    
    func getMonthlyTotalExpenses(for months: Int) -> [(Date, Double)] {
        let calendar = Calendar.current
        let currentDate = Date()
        
        return (0..<months).map { monthsAgo -> (Date, Double) in
            let date = calendar.date(byAdding: .month, value: -monthsAgo, to: currentDate)!
            let total = getMonthTotal(for: date)
            return (date, total)
        }
        .reversed()
    }
    
    private func getMonthTotal(for date: Date) -> Double {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        return expenses
            .filter { expense in
                let expenseMonth = calendar.component(.month, from: expense.date)
                let expenseYear = calendar.component(.year, from: expense.date)
                return expenseMonth == month && expenseYear == year &&
                    (!expense.isRecurring || (expense.isRecurring && (expense.isPaid ?? false)))
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func calculateTotalMonthlyExpenses() {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        totalMonthlyExpenses = expenses
            .filter { expense in
                let expenseMonth = calendar.component(.month, from: expense.date)
                let expenseYear = calendar.component(.year, from: expense.date)
                return expenseMonth == currentMonth && expenseYear == currentYear &&
                    (!expense.isRecurring || (expense.isRecurring && (expense.isPaid ?? false)))
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getRecurringExpenses(forMonth month: Int, year: Int) -> [Expense] {
        expenses.filter { expense in
            let isRecurring = expense.isRecurring
            let expenseDate = expense.date
            let expenseMonth = Calendar.current.component(.month, from: expenseDate)
            let expenseYear = Calendar.current.component(.year, from: expenseDate)
            return isRecurring && expenseMonth == month && expenseYear == year
        }
    }

    func markAsPaid(expenseId: UUID) {
        guard let index = expenses.firstIndex(where: { $0.id == expenseId }) else { return }
        
        // Crear una copia del gasto con el estado actualizado
        var updatedExpense = expenses[index]
        updatedExpense.isPaid = true
        
        // Actualizar el estado local primero
        DispatchQueue.main.async { [weak self] in
            self?.expenses[index] = updatedExpense
            // Forzar la actualización de la vista
            self?.objectWillChange.send()
            self?.needsRefresh.toggle()
        }
        
        // Actualizar en Firebase
        firebaseService.saveExpense(updatedExpense)
        
        // Recalcular el total mensual
        calculateTotalMonthlyExpenses()
    }
    
    func checkAutomaticPayments() {
        let today = Date()
        let calendar = Calendar.current
        
        for expense in expenses where expense.isRecurring && expense.isAutomaticPayment && !(expense.isPaid ?? false) {
            if calendar.isDate(expense.date, inSameDayAs: today) {
                markAsPaid(expenseId: expense.id)
            }
        }
    }
}
