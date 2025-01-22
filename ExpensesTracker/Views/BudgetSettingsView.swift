import SwiftUI

struct BudgetSettingsView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @State private var selectedMonth = Date()
    
    var body: some View {
        List {
            Section {
                DatePicker(
                    "Mes", // Translated text
                    selection: $selectedMonth,
                    displayedComponents: [.date] // Focuses on date only (month and year)
                )
                .datePickerStyle(.compact) // Uses compact style for month and year
                .onChange(of: selectedMonth) { _ in
                    // Ensures the date is always the start of the month
                    selectedMonth = selectedMonth.startOfMonth
                }
            }
            
            Section("Presupuestos por categoría") { // Translated text
                ForEach(expenseViewModel.categories) { category in
                    NavigationLink {
                        CategoryBudgetView(category: category, month: selectedMonth)
                    } label: {
                        CategoryBudgetRow(category: category, month: selectedMonth)
                    }
                }
            }
            
            Section("Gestión de deudas") { // Translated text
                NavigationLink(destination: DebtDashboardView()) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                        Text("Gestionar deudas") // Translated text
                    }
                }
            }
        }
        .navigationTitle("Configuración de presupuesto") // Translated text
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
                            Text("S/. \(budget.amount, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                } else {
                    Text("Sin presupuesto establecido") // Translated text
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
                TextField("Monto del presupuesto", text: $budgetAmount) // Translated text
                    .keyboardType(.decimalPad)
            } header: {
                Text("Presupuesto mensual") // Translated text
            } footer: {
                Text("Establece la cantidad máxima que deseas gastar en esta categoría por mes.") // Translated text
            }
            
            if let budget = expenseViewModel.getBudget(for: category.id, month: month) {
                Section {
                    Button("Eliminar presupuesto", role: .destructive) { // Translated text
                        showingDeleteAlert = true
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") { // Translated text
                    saveBudget()
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
        .alert("Eliminar presupuesto", isPresented: $showingDeleteAlert) { // Translated text
            Button("Cancelar", role: .cancel) { } // Translated text
            Button("Eliminar", role: .destructive) { // Translated text
                removeBudget()
                dismiss()
            }
        } message: {
            Text("¿Estás seguro de que deseas eliminar el presupuesto para esta categoría?") // Translated text
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
        // Loads the budget when the view appears
        if let budget = expenseViewModel.getBudget(for: category.id, month: month) {
            budgetAmount = String(format: "%.2f", budget.amount)
        }
    }
}

// Helper extension to get the start of the month
extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}
