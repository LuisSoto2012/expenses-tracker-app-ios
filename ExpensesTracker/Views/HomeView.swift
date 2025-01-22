import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Monthly summary card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gastos Mensuales")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("$\(expenseViewModel.totalMonthlyExpenses, specifier: "%.2f")")
                            .font(.system(size: 34, weight: .bold))
                        
                        Divider()
                        
                        // Budget Overview
                        Text("Visión General del Presupuesto")
                            .font(.headline)
                        
                        ForEach(expenseViewModel.categories) { category in
                            if let budget = expenseViewModel.getBudget(for: category.id, month: Date()) {
                                BudgetProgressView(
                                    category: category,
                                    budget: budget,
                                    progress: expenseViewModel.getBudgetProgress(for: category.id, month: Date())
                                )
                            }
                        }
                        
                        Divider()
                        
                        Text("Gastos Recientes")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    // Recent expenses list
                    LazyVStack(spacing: 12) {
                        ForEach(expenseViewModel.expenses) { expense in
                            ExpenseRowView(expense: expense)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Inicio")
            .toolbar {
                Button(action: {
                    // Agregar nuevo gasto acción
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
    }
}

struct BudgetProgressView: View {
    let category: Category
    let budget: Budget
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category.name)
                    .font(.subheadline)
                Spacer()
                Text("$\(budget.amount, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: min(progress, 1.0))
                .tint(progress > 1.0 ? .red : category.uiColor)
        }
        .padding(.vertical, 4)
    }
}
