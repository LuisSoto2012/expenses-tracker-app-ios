import SwiftUI

struct AccountFormView: View {
    enum Mode {
        case add
        case edit(Account)
    }
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var accountViewModel = AccountViewModel()
    @ObservedObject var incomeViewModel: IncomeViewModel
    
    let mode: Mode
    @State private var name: String = ""
    @State private var balance: Double = 0.0
    @State private var currency: String = "PEN"
    @State private var isDefault: Bool = false
    @State private var selectedPaymentMethods: [PaymentMethod] = []
    
    @State private var showPaymentSelection = false
    
    init(mode: Mode, incomeViewModel: IncomeViewModel) {
       self.mode = mode
       self.incomeViewModel = incomeViewModel
       
       if case .edit(let account) = mode {
           // Inicializar las propiedades del account
           _name = State(initialValue: account.name)
           _balance = State(initialValue: account.currentBalance)
           _currency = State(initialValue: account.currency)
           _isDefault = State(initialValue: account.isDefault)
           
           // Filtrar los métodos de pago que ya están asociados al account
           let filteredMethods = incomeViewModel.paymentMethods.filter { account.paymentMethods.contains($0.id) }
           print("Métodos de pago seleccionados: \(filteredMethods)")  // Imprime los métodos seleccionados
           
           // Inicializar selectedPaymentMethods con los métodos de pago filtrados
           _selectedPaymentMethods = State(initialValue: filteredMethods)
       } else {
           // Inicializar selectedPaymentMethods como vacío en modo .add
           _selectedPaymentMethods = State(initialValue: [])
       }
   }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información de la Cuenta")) {
                    TextField("Nombre de Cuenta", text: $name)
                    
                    Picker("Moneda", selection: $currency) {
                        Text("PEN").tag("PEN")
                        Text("USD").tag("USD")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    TextField("Balance", value: $balance, formatter: currencyFormatter)
                        .keyboardType(.decimalPad)
                    
                    Toggle("Cuenta Predeterminada", isOn: $isDefault)
                }
                
                Section(header: Text("Métodos de Pago")) {
                    if selectedPaymentMethods.isEmpty {
                        Button(action: { showPaymentSelection = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Agregar Métodos de Pago")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(selectedPaymentMethods) { method in
                                    PaymentMethodCard(
                                        paymentMethod: method,
                                        isSelected: .constant(false)
                                    )
                                        .frame(width: 250, height: 150)
//                                        .overlay(
//                                            RoundedRectangle(cornerRadius: 15)
//                                                .stroke(Color.blue, lineWidth: 3)
//                                        )
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                selectedPaymentMethods.removeAll { $0.id == method.id }
                                            } label: {
                                                Label("Eliminar", systemImage: "trash")
                                            }
                                        }
                                }
                                
                                // Botón para agregar métodos de pago
                                Button(action: { showPaymentSelection = true }) {
                                    VStack {
                                        Image(systemName: "plus.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.blue)
                                        Text("Agregar")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(15)
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                        .frame(height: 190)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveAccount()
                        dismiss()
                    }
                    .disabled(name.isEmpty || currency.isEmpty)
                }
            }
//            .onAppear {
//                if case .edit(let account) = mode {
//                    selectedPaymentMethods = incomeViewModel.paymentMethods.filter { account.paymentMethods.contains($0.id) }
//                }
//            }
            .sheet(isPresented: $showPaymentSelection) {
                paymentSelectionView
            }
        }
    }
    
    private var title: String {
        switch mode {
        case .add:
            return "Nueva Cuenta"
        case .edit:
            return "Editar Cuenta"
        }
    }
    
    private var paymentSelectionView: some View {
        PaymentMethodSelectionView(
            selectedPaymentMethods: $selectedPaymentMethods,
            availablePaymentMethods: $incomeViewModel.paymentMethods
        )
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currency == "PEN" ? "S/. " : "$ "
        return formatter
    }
    
    private func saveAccount() {
        let accountID: UUID
        if case .edit(let existingAccount) = mode {
            accountID = existingAccount.id
        } else {
            accountID = UUID()
        }

        let account = Account(
            id: accountID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            balance: balance,
            currency: currency,
            paymentMethods: selectedPaymentMethods.map { $0.id },
            isDefault: isDefault
        )

        switch mode {
        case .edit:
            accountViewModel.updateAccount(account)
        case .add:
            accountViewModel.addAccount(account)
        }
    }
}
