import SwiftUI

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: IncomeViewModel
    
    @State private var name = ""
    @State private var type: PaymentMethodType = .debitCard
    @State private var lastFourDigits = ""
    @State private var expiryDate = Date()
    @State private var colorHex = "#007AFF"
    @State private var isDefault = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Payment Method Details") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(PaymentMethodType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    if type != .cash {
                        TextField("Last 4 Digits", text: $lastFourDigits)
                            .keyboardType(.numberPad)
                        DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                    }
                }
                
                Section {
                    ColorPicker("Card Color", selection: Binding(
                        get: { Color(hex: colorHex) ?? .blue },
                        set: { colorHex = $0.toHex() ?? "#007AFF" }
                    ))
                    Toggle("Set as Default", isOn: $isDefault)
                }
            }
            .navigationTitle("Add Payment Method")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePaymentMethod()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func savePaymentMethod() {
        let method = PaymentMethod(
            name: name,
            type: type,
            colorHex: colorHex,
            lastFourDigits: type != .cash ? lastFourDigits : nil,
            expiryDate: type != .cash ? expiryDate : nil,
            isDefault: isDefault
        )
        viewModel.addPaymentMethod(method)
    }
} 