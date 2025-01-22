import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @State private var showDeleteConfirmation = false
    @State private var expenseToDelete: Expense?
    
    private var category: Category? {
        expenseViewModel.categories.first { $0.id == expense.categoryId }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
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
                    if let notes = expense.notes {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(dateFormatter.string(from: expense.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
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
        amount: 42.50,
        notes: "Compra de supermercado",
        categoryId: Category.defaults[0].id,
        isRecurring: true,
        recurrenceInterval: .monthly
    ))
    .environmentObject(ExpenseViewModel())
} 
