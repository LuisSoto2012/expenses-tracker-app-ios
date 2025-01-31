import SwiftUI

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: IncomeViewModel
    
    @State private var name = ""
    @State private var type: PaymentMethodType = .debitCard
    @State private var lastFourDigits = ""
    @State private var expiryDate = Date()
    @State private var colorHexPrimary = "#007AFF"
    @State private var colorHexSecondary = "#34C759"
    @State private var gradientDirection: GradientDirection = .topLeftToBottomRight
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
                
                Section("Card Appearance") {
                    ColorPicker("Primary Color", selection: Binding(
                        get: { Color(hex: colorHexPrimary) ?? .blue },
                        set: { colorHexPrimary = $0.toHex() ?? "#007AFF" }
                    ))
                    
                    ColorPicker("Secondary Color", selection: Binding(
                        get: { Color(hex: colorHexSecondary) ?? .green },
                        set: { colorHexSecondary = $0.toHex() ?? "#34C759" }
                    ))
                    
                    Picker("Gradient Direction", selection: $gradientDirection) {
                        ForEach(GradientDirection.allCases, id: \.self) { direction in
                            Text(direction.rawValue).tag(direction)
                        }
                    }
                    
                    Toggle("Set as Default", isOn: $isDefault)
                    
                    // Vista previa del color con dirección seleccionada
                    VStack {
                        Text("Preview")
                            .font(.headline)
                            .padding(.top)
                        
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: colorHexPrimary) ?? .blue,
                                        Color(hex: colorHexSecondary) ?? .green
                                    ]),
                                    startPoint: gradientDirection.startPoint,
                                    endPoint: gradientDirection.endPoint
                                )
                            )
                            .frame(height: 100)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                    }
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
            colorHexPrimary: colorHexPrimary,
            colorHexSecondary: colorHexSecondary,
            gradientDirection: gradientDirection,
            lastFourDigits: type != .cash ? lastFourDigits : nil,
            expiryDate: type != .cash ? expiryDate : nil,
            isDefault: isDefault
        )
        viewModel.addPaymentMethod(method)
    }
}
