import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @State private var showDeleteConfirmation = false
    @State private var expenseToDelete: Expense?
    @State private var isLoadingPayment = false
    @State private var showEditSheet = false
    @State private var newAmount: Double = 0.0
    
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
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 44, height: 44)
                } else {
                    Button(action: {
                        withAnimation {
                            isLoadingPayment = true
                            // Marcar como pagado después de un breve retraso
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                expenseViewModel.markAsPaid(expenseId: expense.id)
                                isLoadingPayment = false
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
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if expense.isRecurring {
                Button {
                    newAmount = expense.amount
                    showEditSheet = true
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            VStack(spacing: 24) {
                // Título del sheet
                Text("Editar Monto (S/.)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                // Campo de texto para ingresar el monto
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monto:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextField("Ingrese el monto", value: $newAmount, formatter: CurrencyFormatter.pen)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Botones para Cancelar y Guardar
                HStack(spacing: 16) {
                    Button(action: {
                        showEditSheet = false
                    }) {
                        Text("Cancelar")
                            .font(.body)
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        expenseViewModel.updateExpense(expense, newAmount: newAmount)
                        showEditSheet = false
                    }) {
                        Text("Guardar")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding()
            .presentationDetents([.height(250), .medium])
            .presentationDragIndicator(.visible)
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
