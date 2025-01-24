import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    
    @State private var name: String = ""
    @State private var amount: Double = 0.0
    @State private var notes: String = ""
    @State private var date = Date()
    @State private var selectedCategoryId: UUID?
    @State private var isRecurring = false
    @State private var recurrenceInterval: RecurrenceInterval = .monthly
    @State private var isFixed = false
    @State private var endDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                // Name Section
                Section {
                    TextField("Nombre", text: $name)
                } header: {
                    Text("Nombre")
                }
                
                // Amount Section
                Section {
                    TextField("Monto", value: $amount, formatter: CurrencyFormatter.pen)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Monto (S/.)")
                }
                
                // Category Section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(expenseViewModel.categories) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: category.id == selectedCategoryId
                                ) {
                                    selectedCategoryId = category.id
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Categoría")
                }
                
                // Date & Notes Section
                Section {
                    DatePicker("Fecha", selection: $date, displayedComponents: .date)
                    TextField("Notas", text: $notes)
                } header: {
                    Text("Detalles")
                }
                
                // Recurring Expense Section
                Section {
                    Toggle("Gasto Recurrente", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Intervalo", selection: $recurrenceInterval) {
                            Text("Diario").tag(RecurrenceInterval.daily)
                            Text("Semanal").tag(RecurrenceInterval.weekly)
                            Text("Mensual").tag(RecurrenceInterval.monthly)
                            Text("Anual").tag(RecurrenceInterval.yearly)
                        }
                        DatePicker("Fecha Fin", selection: $endDate, displayedComponents: .date)
                        
                        Toggle("Monto Fijo", isOn: $isFixed)
                    }
                } header: {
                    Text("Recurrencia")
                }
            }
            .navigationTitle("Nuevo Gasto")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveExpense()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return amount > 0 && selectedCategoryId != nil
    }
    
    private func saveExpense() {
        guard let categoryId = selectedCategoryId else {
            return
        }
        
        let expense = Expense(
            name: name,
            amount: amount,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            categoryId: categoryId,
            isRecurring: isRecurring,
            recurrenceInterval: isRecurring ? recurrenceInterval : nil,
            isFixed: isRecurring ? isFixed : nil
        )
        
        if isRecurring {
            expenseViewModel.addRecurringExpense(expense, endDate: endDate)
        } else {
            expenseViewModel.addExpense(expense)
        }
        dismiss()
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(category.uiColor.opacity(isSelected ? 1 : 0.3))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category.icon)
                        .foregroundColor(isSelected ? .white : category.uiColor)
                }
                
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? category.uiColor : .primary)
            }
        }
    }
}
