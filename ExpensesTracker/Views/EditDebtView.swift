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
                Section("Debt Details") {
                    TextField("Debt Name", text: $name)
                    
                    TextField("Total Amount", value: $totalAmount, formatter: CurrencyFormatter.usd)
                        .keyboardType(.decimalPad)
                    
                    Stepper("Number of Installments: \(numberOfInstallments)", value: $numberOfInstallments, in: 1...36)
                    
                    TextField("Description", text: $description)
                    
                    Toggle("Share with Partner", isOn: $sharedWithPartner)
                }
            }
            .navigationTitle("Edit Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
