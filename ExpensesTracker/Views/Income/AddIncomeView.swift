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
                Section("Detalles de Ingreso") {
                    TextField("Nombre", text: $name)
                    Picker("Tipo", selection: $type) {
                        ForEach(IncomeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Monto", value: $amount, formatter: CurrencyFormatter.pen)
                        .keyboardType(.decimalPad)
                    Picker("Frequencia", selection: $frequency) {
                        ForEach(IncomeFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section("Metodo de Pago") {
                    Picker("Metodo de Pago", selection: $selectedPaymentMethodId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(viewModel.paymentMethods) { method in
                            Text(method.name).tag(method.id as UUID?)
                        }
                    }
                }
            }
            .navigationTitle("Agregar Ingreso")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
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
