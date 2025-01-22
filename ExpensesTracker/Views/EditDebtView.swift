import SwiftUI

struct EditDebtView: View {
    @Environment(\.dismiss) private var dismiss
    let debt: Debt
    @ObservedObject var viewModel: DebtViewModel
    
    @State private var name: String
    @State private var totalAmount: Double
    @State private var numberOfInstallments: Int
    @State private var description: String
    @State private var sharedWithPartner: Bool
    
    init(debt: Debt, viewModel: DebtViewModel) {
        self.debt = debt
        self.viewModel = viewModel
        _name = State(initialValue: debt.name)
        _totalAmount = State(initialValue: debt.totalAmount)
        _numberOfInstallments = State(initialValue: debt.numberOfInstallments)
        _description = State(initialValue: debt.description ?? "")
        _sharedWithPartner = State(initialValue: debt.sharedWithPartner)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Detalles de la Deuda") {
                    TextField("Nombre de la Deuda", text: $name)
                    
                    TextField("Monto Total", value: $totalAmount, formatter: CurrencyFormatter.pen)
                        .keyboardType(.decimalPad)
                    
                    Stepper("Número de Cuotas: \(numberOfInstallments)", value: $numberOfInstallments, in: 1...36)
                    
                    TextField("Descripción", text: $description)
                    
                    Toggle("Compartir con Pareja", isOn: $sharedWithPartner)
                }
            }
            .navigationTitle("Editar Deuda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(name.isEmpty || totalAmount <= 0 || numberOfInstallments <= 0)
                }
            }
        }
    }
    
    private func saveChanges() {
        viewModel.updateDebt(debt) { debt in
            debt.name = name
            debt.totalAmount = totalAmount
            debt.description = description.isEmpty ? nil : description
            debt.sharedWithPartner = sharedWithPartner
            debt.regenerateInstallments(newTotalAmount: totalAmount, newNumberOfInstallments: numberOfInstallments)
        }
    }
}
