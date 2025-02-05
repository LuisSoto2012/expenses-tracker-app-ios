import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var accountViewModel: AccountViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    
    // Obtener la cuenta predeterminada
    private var defaultAccount: Account? {
        accountViewModel.accounts.first(where: { $0.isDefault })
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Account Balances
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(accountViewModel.accounts) { account in
                                AccountBalanceCard(account: account)
                                    .frame(width: 300)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Información de la cuenta predeterminada
                    if let account = defaultAccount {
                        AccountSummaryView(account: account)
                    }
                    
                    // Monthly summary card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gastos Mensuales")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("S/. \(expenseViewModel.totalMonthlyExpenses, specifier: "%.2f")")
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
                        ForEach(expenseViewModel.getRecentExpenses()) { expense in
                            ExpenseRowView(expense: expense)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .refreshable {
                // Acción para recargar los datos
                expenseViewModel.reloadExpenses()
            }
            .navigationTitle("Inicio")
        }
    }
}

// Vista de Resumen de Cuenta Predeterminada
struct AccountSummaryView: View {
    let account: Account
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cuenta Predeterminada")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(account.name)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text("Saldo: ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(verbatim: CurrencyFormatter.pen.string(from: NSNumber(value: account.currentBalance)) ?? "S/. 0.00")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(account.currentBalance >= 0 ? .green : .red)
            }
            
            Divider()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
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
                Text("S/. \(budget.amount, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: min(progress, 1.0))
                .tint(progress > 1.0 ? .red : category.uiColor)
        }
        .padding(.vertical, 4)
    }
}

struct AccountBalanceCard: View {
    let account: Account
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(account.color))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: account.type.icon)
                            .foregroundColor(.white)
                    )
                
                Text(account.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(account.currency) \(account.currentBalance, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(account.currentBalance >= 0 ? .primary : .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
