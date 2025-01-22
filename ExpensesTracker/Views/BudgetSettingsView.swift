import SwiftUI

struct BudgetSettingsView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @State private var selectedMonth = Date()
    
    var body: some View {
        List {
            Section {
                DatePicker(
                    "Month",
                    selection: $selectedMonth,
                    displayedComponents: [.date] // Se enfoca solo en la fecha
                )
                .datePickerStyle(.compact) // Cambia al estilo compacto (mes y año)
                .onChange(of: selectedMonth) { _ in
                    // Garantiza que siempre sea el inicio del mes
                    selectedMonth = selectedMonth.startOfMonth
                }
            }
            
            Section("Category Budgets") {
                ForEach(expenseViewModel.categories) { category in
                    NavigationLink {
                        CategoryBudgetView(category: category, month: selectedMonth)
                    } label: {
                        CategoryBudgetRow(category: category, month: selectedMonth)
                    }
                }
            }
            
            Section(String(localized: "debt_management")) {
                NavigationLink(destination: DebtDashboardView()) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                        Text(String(localized: "manage_debts"))
                    }
                }
            }
        }
        .navigationTitle(String(localized: "budget_settings"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CategoryBudgetRow: View {
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    let category: Category
    let month: Date
    
    private var budget: Budget? {
        expenseViewModel.getBudget(for: category.id, month: month)
    }
    
    private var progress: Double {
        expenseViewModel.getBudgetProgress(for: category.id, month: month)
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(category.uiColor)
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: category.icon)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                
                if let budget = budget {
                    ProgressView(value: min(progress, 1.0))
                        .tint(progress > 1.0 ? .red : category.uiColor)
                        .overlay(alignment: .trailing) {
                            Text("$\(budget.amount, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                } else {
                    Text("No budget set")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
        }
    }
}

struct CategoryBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    
    let category: Category
    let month: Date
    
    @State private var budgetAmount: String = ""
    @State private var showingDeleteAlert = false

    var body: some View {
        Form {
            Section {
                TextField("Budget Amount", text: $budgetAmount)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Monthly Budget")
            } footer: {
                Text("Set the maximum amount you want to spend in this category per month.")
            }
            
            if let budget = expenseViewModel.getBudget(for: category.id, month: month) {
                Section {
                    Button("Remove Budget", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveBudget()
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
        .alert("Remove Budget", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeBudget()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to remove the budget for this category?")
        }
        .onAppear {
            loadBudget()
        }
    }
    
    private var isValid: Bool {
        guard let amount = Double(budgetAmount) else { return false }
        return amount > 0
    }
    
    private func saveBudget() {
        guard let amount = Double(budgetAmount) else { return }
        expenseViewModel.setBudget(amount, for: category.id, month: month)
    }
    
    private func removeBudget() {
        expenseViewModel.removeBudget(for: category.id, month: month)
    }
    
    private func loadBudget() {
        // Carga el presupuesto cuando la vista aparece
        if let budget = expenseViewModel.getBudget(for: category.id, month: month) {
            budgetAmount = String(format: "%.2f", budget.amount)
        }
    }
}

// Helper extension to get start of month
extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
} 
