import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var debtViewModel: DebtViewModel
    @State private var showingAddExpense = false
    @State private var selectedMonth = Date()
    @State private var selectedCategoryId: UUID?
    
    private var filteredExpenses: [Expense] {
        expenseViewModel.getFilteredExpenses(
            month: selectedMonth,
            categoryId: selectedCategoryId
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Section
                VStack(spacing: 16) {
                    // Month Picker
                    DatePicker(
                        "Seleccionar Mes",
                        selection: $selectedMonth,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryFilterChip(
                                name: "Todos",
                                isSelected: selectedCategoryId == nil
                            ) {
                                selectedCategoryId = nil
                            }
                            
                            ForEach(expenseViewModel.categories) { category in
                                CategoryFilterChip(
                                    name: category.name,
                                    isSelected: category.id == selectedCategoryId
                                ) {
                                    selectedCategoryId = category.id
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                // Expenses List
                List {
                    ForEach(filteredExpenses) { expense in
                        ExpenseRowView(expense: expense)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteExpense) // Swipe to delete
                }
                .listStyle(.plain)
            }
            .navigationTitle("Gastos")
            .toolbar {
                Button(action: {
                    showingAddExpense = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
        }
    }
    
    // Delete Handler
    private func deleteExpense(at offsets: IndexSet) {
        offsets.forEach { index in
            let expense = filteredExpenses[index]
            
            // Eliminar el pago de deuda asociado
            if let associatedDebtInstallment = debtViewModel.getInstallment(for: expense) {
                debtViewModel.undoPayment(for: debt, installmentNumber: associatedDebtInstallment.number)
            }
            
            // Eliminar el gasto
            expenseViewModel.deleteExpense(expense)
        }
    }
}

struct CategoryFilterChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
