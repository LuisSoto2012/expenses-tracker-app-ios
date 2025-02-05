import SwiftUI

struct AccountManagementView: View {
    @EnvironmentObject private var accountViewModel: AccountViewModel
    @EnvironmentObject private var incomeViewModel: IncomeViewModel
    @State private var showingAddAccount = false
    @State private var showingSyncConfirmation = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(accountViewModel.accounts) { account in
                        NavigationLink {
                            TransactionsView(account: account)
                                .environmentObject(accountViewModel)
                        } label: {
                            AccountRowView(account: account)
                        }
                    }
                } header: {
                    Text("Cuentas")
                }
                
                Section {
                    Button(action: {
                        showingSyncConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sincronizar Transacciones")
                        }
                    }
                    
                    Button(action: {
                        showingAddAccount = true
                    }) {
                        Label("Agregar Cuenta", systemImage: "plus.circle.fill")
                    }
                    
                    NavigationLink {
                        PaymentMethodsView(viewModel: incomeViewModel)
                    } label: {
                        Label("Métodos de Pago", systemImage: "creditcard")
                    }
                } header: {
                    Text("Acciones")
                }
            }
            .navigationTitle("Cuentas")
            .sheet(isPresented: $showingAddAccount) {
                AccountFormView(mode: .add, incomeViewModel: incomeViewModel)
                    .environmentObject(accountViewModel)
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
}

// MARK: - Account Row View
struct AccountRowView: View {
    let account: Account
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(account.color))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: account.type.icon)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading) {
                Text(account.name)
                    .font(.headline)
                Text(account.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(account.currency) \(account.currentBalance, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(account.currentBalance >= 0 ? .primary : .red)
            }
            
            if account.isDefault {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
}
