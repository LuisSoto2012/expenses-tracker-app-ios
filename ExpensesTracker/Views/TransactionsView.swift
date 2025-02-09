import SwiftUI

struct TransactionsView: View {
    let account: Account
    @EnvironmentObject private var accountViewModel: AccountViewModel
    
    var body: some View {
        List {
            ForEach(accountViewModel.getTransactions(for: account.id)) { transaction in
                TransactionRowView(transaction: transaction)
            }
        }
        .navigationTitle("Transacciones de \(account.name)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        // TODO: Implementar filtro por fecha
                    }) {
                        Label("Filtrar por Fecha", systemImage: "calendar")
                    }
                    
                    Button(action: {
                        // TODO: Implementar filtro por tipo
                    }) {
                        Label("Filtrar por Tipo", systemImage: "tag")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.description)
                    .font(.headline)
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(transaction.isIncoming ? "+" : "-")
                .font(.headline)
                .foregroundColor(transaction.isIncoming ? .green : .red) +
            Text(" \(abs(transaction.amount), specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(transaction.isIncoming ? .green : .red)
        }
        .padding(.vertical, 8)
    }
}
