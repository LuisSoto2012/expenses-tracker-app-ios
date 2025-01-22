import SwiftUI
import FirebaseAuth
import Combine

class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var categories: [Category] = []
    @Published var budgets: [Budget] = []
    @Published var totalMonthlyExpenses: Double = 0
    @Published var isLoading = false
    
    private let firebaseService = FirebaseService()
    
    init() {
        setupDataSync()
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
            firebaseService.saveExpense(expense)
        }
        
    func deleteExpense(_ expense: Expense) {
        firebaseService.deleteExpense(id: expense.id)
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
    
    func getFilteredExpenses(month: Date, categoryId: UUID?) -> [Expense] {
        let calendar = Calendar.current
        let monthComponent = calendar.component(.month, from: month)
        let yearComponent = calendar.component(.year, from: month)
        
        return expenses.filter { expense in
            let expenseMonth = calendar.component(.month, from: expense.date)
            let expenseYear = calendar.component(.year, from: expense.date)
            
            let monthMatches = expenseMonth == monthComponent && expenseYear == yearComponent
            let categoryMatches = categoryId == nil || expense.categoryId == categoryId
            
            return monthMatches && categoryMatches
        }
        .sorted { $0.date > $1.date }
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
            
            if expenseMonth == month && expenseYear == year {
                categoryTotals[expense.categoryId, default: 0] += expense.amount
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
                return expenseMonth == month && expenseYear == year
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
                return expenseMonth == currentMonth && expenseYear == currentYear
            }
            .reduce(0) { $0 + $1.amount }
    }
} 
