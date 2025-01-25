import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @State private var showDeleteConfirmation = false
    @State private var expenseToDelete: Expense?
    @State private var isLoadingPayment = false
    
    private var category: Category? {
        expenseViewModel.categories.first { $0.id == expense.categoryId }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    struct StatusBadge: View {
        let isPaid: Bool
        
        var body: some View {
            Text(isPaid ? "Pagado" : "Pendiente")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isPaid ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                .foregroundColor(isPaid ? .green : .orange)
                .clipShape(Capsule())
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(category?.uiColor ?? .gray)
                    .frame(width: 44, height: 44)
                
                Image(systemName: category?.icon ?? "questionmark")
                    .foregroundColor(.white)
            }
            
            // Expense details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category?.name ?? "Desconocido")
                        .font(.headline)
                    
                    if expense.isRecurring {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(expense.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(dateFormatter.string(from: expense.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Mostrar el StatusBadge solo si el gasto es recurrente
                if expense.isRecurring {
                    StatusBadge(isPaid: expense.isPaid ?? false)  // Dependiendo de isPaid
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Mostrar botón "Pagar" solo si el gasto es recurrente y no está pagado
            if expense.isRecurring, !(expense.isPaid ?? false) {
                if isLoadingPayment {
                    // Mostrar indicador de carga
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 44, height: 44)
                } else {
                    Button(action: {
                        withAnimation {
                            isLoadingPayment = true
                        }
                        // Simular una llamada de red o pago
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                isLoadingPayment = false
                                expenseViewModel.markAsPaid(expenseId: expense.id)
                            }
                        }
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .frame(width: 44, height: 44)
                }
            }
            
            // Amount
            Text("S/. \(expense.amount, specifier: "%.2f")")
                .font(.headline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                // Set the expense to be deleted and show the confirmation alert
                expenseToDelete = expense
                showDeleteConfirmation = true
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Eliminar Gasto"),
                message: Text("¿Estás seguro de que quieres eliminar este gasto?"),
                primaryButton: .destructive(Text("Eliminar")) {
                    if let expenseToDelete = expenseToDelete {
                        expenseViewModel.deleteExpense(expenseToDelete)
                    }
                },
                secondaryButton: .cancel(Text("Cancelar"))
            )
        }
    }
}

#Preview {
    ExpenseRowView(expense: Expense(
        name: "Compra de supermercado",
        amount: 42.50,
        notes: "Compra de supermercado",
        categoryId: Category.defaults[0].id,
        isRecurring: true,
        recurrenceInterval: .monthly
    ))
    .environmentObject(ExpenseViewModel())
} 
