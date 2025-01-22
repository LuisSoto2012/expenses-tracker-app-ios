import SwiftUI

struct AddDebtView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DebtViewModel
    
    @State private var name = ""
    @State private var totalAmount: Double = 0.0
    @State private var numberOfInstallments = 12
    @State private var startDate = Date()
    @State private var description = ""
    @State private var sharedWithPartner = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Detalles de la Deuda") {
                    TextField("Nombre de la Deuda", text: $name)
                    
                    TextField("Monto Total", value: $totalAmount, formatter: CurrencyFormatter.pen)
                        .keyboardType(.decimalPad)
                    
                    Stepper("Número de Cuotas: \(numberOfInstallments)", value: $numberOfInstallments, in: 1...120)
                    
                    DatePicker("Fecha de Inicio", selection: $startDate, displayedComponents: .date)
                }
                
                Section("Información Adicional") {
                    TextField("Descripción (Opcional)", text: $description)
                    
                    Toggle("Compartir con Pareja", isOn: $sharedWithPartner)
                }
            }
            .navigationTitle("Agregar Nueva Deuda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveDebt()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveDebt() {
        let debt = Debt(
            name: name,
            totalAmount: totalAmount,
            numberOfInstallments: numberOfInstallments,
            startDate: startDate,
            description: description,
            sharedWithPartner: sharedWithPartner
        )
        viewModel.addDebt(debt)
    }
}
