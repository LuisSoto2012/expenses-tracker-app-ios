import SwiftUI

struct AccountManagementView: View {
    @EnvironmentObject private var accountViewModel: AccountViewModel
    @EnvironmentObject private var incomeViewModel: IncomeViewModel
    @State private var showingAddAccount = false
    @State private var showingSyncConfirmation = false
    @State private var selectedAccount: Account?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Total Balance Card
                    VStack(spacing: 8) {
                        Text("Balance Total")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(totalBalance, format: .currency(code: "PEN"))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(totalBalanceColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    // Accounts List
                    LazyVStack(spacing: 12) {
                        ForEach(accountViewModel.accounts) { account in
                            AccountCard(account: account)
                                .onTapGesture {
                                    selectedAccount = account
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Cuentas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAccount = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSyncConfirmation = true
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AccountFormView(mode: .add, incomeViewModel: incomeViewModel)
                    .environmentObject(accountViewModel)
            }
            .sheet(item: $selectedAccount) { account in
                NavigationView {
                    AccountFormView(mode: .edit(account), incomeViewModel: incomeViewModel)
                        .environmentObject(accountViewModel)
                }
            }
            .alert("Sincronizar Transacciones", isPresented: $showingSyncConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Sincronizar") {
                    accountViewModel.syncTransactions()
                }
            } message: {
                Text("¿Deseas sincronizar las transacciones para todos los gastos existentes?")
            }
        }
    }
    
    private var totalBalance: Double {
        accountViewModel.accounts.reduce(0) { $0 + $1.currentBalance }
    }
    
    private var totalBalanceColor: Color {
        totalBalance >= 0 ? .primary : .red
    }
}

// MARK: - Account Card View
struct AccountCard: View {
    let account: Account
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Circle
            Circle()
                .fill(Color(account.color))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: account.type.icon)
                        .foregroundColor(.white)
                        .font(.title3)
                )
            
            // Account Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(account.name)
                        .font(.headline)
                    
                    if account.isDefault {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                    }
                }
                
                Text(account.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Balance
            VStack(alignment: .trailing, spacing: 4) {
                Text(account.currentBalance, format: .currency(code: account.currency))
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
