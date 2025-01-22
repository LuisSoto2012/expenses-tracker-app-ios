import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    
    @State private var amount: String = ""
    @State private var notes: String = ""
    @State private var date = Date()
    @State private var selectedCategoryId: UUID?
    @State private var isRecurring = false
    @State private var recurrenceInterval: RecurrenceInterval = .monthly
    @State private var isFixed = false
    
    var body: some View {
        NavigationView {
            Form {
                // Amount Section
                Section {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Amount")
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
                    Text("Category")
                }
                
                // Date & Notes Section
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes", text: $notes)
                } header: {
                    Text("Details")
                }
                
                // Recurring Expense Section
                Section {
                    Toggle("Recurring Expense", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Interval", selection: $recurrenceInterval) {
                            Text("Daily").tag(RecurrenceInterval.daily)
                            Text("Weekly").tag(RecurrenceInterval.weekly)
                            Text("Monthly").tag(RecurrenceInterval.monthly)
                            Text("Yearly").tag(RecurrenceInterval.yearly)
                        }
                        
                        Toggle("Fixed Amount", isOn: $isFixed)
                    }
                } header: {
                    Text("Recurrence")
                }
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        guard let amountDouble = Double(amount),
              amountDouble > 0,
              selectedCategoryId != nil else {
            return false
        }
        return true
    }
    
    private func saveExpense() {
        guard let amountDouble = Double(amount),
              let categoryId = selectedCategoryId else {
            return
        }
        
        let expense = Expense(
            amount: amountDouble,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            categoryId: categoryId,
            isRecurring: isRecurring,
            recurrenceInterval: isRecurring ? recurrenceInterval : nil,
            isFixed: isRecurring ? isFixed : nil
        )
        
        expenseViewModel.addExpense(expense)
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