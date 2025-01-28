import SwiftUI

struct AddIncomeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: IncomeViewModel
    
    @State private var name = ""
    @State private var type: IncomeType = .fixed
    @State private var amount: String = ""
    @State private var frequency: IncomeFrequency = .monthly
    @State private var selectedPaymentMethodId: UUID?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Income Details") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(IncomeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(IncomeFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section("Payment Method") {
                    Picker("Payment Method", selection: $selectedPaymentMethodId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(viewModel.paymentMethods) { method in
                            Text(method.name).tag(method.id as UUID?)
                        }
                    }
                }
            }
            .navigationTitle("Add Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIncome()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveIncome() {
        let income = Income(
            name: name,
            type: type,
            amount: Double(amount) ?? 0,
            frequency: frequency,
            paymentMethod: selectedPaymentMethodId
        )
        viewModel.addIncome(income)
    }
} 
