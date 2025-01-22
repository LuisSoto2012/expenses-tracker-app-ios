import SwiftUI

struct AddDebtView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DebtViewModel
    
    @State private var name = ""
    @State private var totalAmount: Double?
    @State private var numberOfInstallments = 12
    @State private var startDate = Date()
    @State private var description = ""
    @State private var sharedWithPartner = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Debt Details") {
                    TextField("Debt Name", text: $name)
                    
                    TextField("Total Amount (Optional)", value: $totalAmount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    
                    Stepper("Number of Installments: \(numberOfInstallments)", value: $numberOfInstallments, in: 1...120)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                
                Section("Additional Information") {
                    TextField("Description (Optional)", text: $description)
                    
                    Toggle("Share with Partner", isOn: $sharedWithPartner)
                }
            }
            .navigationTitle("Add New Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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