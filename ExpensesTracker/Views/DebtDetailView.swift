import SwiftUI

struct DebtDetailView: View {
    let debt: Debt
    @ObservedObject var viewModel: DebtViewModel
    @State private var showingPaymentSheet = false
    @State private var selectedInstallment: DebtInstallment?
    
    var body: some View {
        List {
            debtInfoSection
            
            installmentsSection
        }
        .navigationTitle(debt.name)
        .sheet(isPresented: $showingPaymentSheet) {
            if let installment = selectedInstallment {
                RegisterPaymentView(
                    debt: debt,
                    installment: installment,
                    viewModel: viewModel
                )
            }
        }
    }
    
    private var debtInfoSection: some View {
        Section("Debt Information") {
            if let amount = debt.totalAmount {
                LabeledContent("Total Amount") {
                    Text(amount.formatted(.currency(code: "USD")))
                }
                
                if let remaining = debt.remainingAmount {
                    LabeledContent("Remaining") {
                        Text(remaining.formatted(.currency(code: "USD")))
                    }
                }
            }
            
            LabeledContent("Status") {
                StatusBadge(status: debt.status)
            }
            
            LabeledContent("Progress") {
                Text("\(Int(debt.progress * 100))%")
            }
            
            if let description = debt.description {
                LabeledContent("Description") {
                    Text(description)
                }
            }
            
            LabeledContent("Shared") {
                Text(debt.sharedWithPartner ? "Yes" : "No")
            }
        }
    }
    
    private var installmentsSection: some View {
        Section("Installments") {
            ForEach(debt.installments) { installment in
                InstallmentRow(installment: installment)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedInstallment = installment
                        showingPaymentSheet = true
                    }
            }
        }
    }
}

struct InstallmentRow: View {
    let installment: DebtInstallment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Installment #\(installment.number)")
                    .font(.headline)
                Spacer()
                if installment.isPaid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Due Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(installment.dueDate.formatted(date: .abbreviated, time: .omitted))
                }
                
                Spacer()
                
                if let amount = installment.amount {
                    VStack(alignment: .trailing) {
                        Text("Amount")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(amount.formatted(.currency(code: "USD")))
                    }
                }
            }
            
            if installment.isPaid {
                HStack {
                    Text("Paid")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let paidAmount = installment.paidAmount {
                        Text(paidAmount.formatted(.currency(code: "USD")))
                    }
                    if let paidDate = installment.paidDate {
                        Text("on \(paidDate.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
                .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RegisterPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    let debt: Debt
    let installment: DebtInstallment
    @ObservedObject var viewModel: DebtViewModel
    
    @State private var amount: Double?
    @State private var showingAmountField = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Specify payment amount", isOn: $showingAmountField)
                    
                    if showingAmountField {
                        TextField("Amount", value: $amount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                    }
                } footer: {
                    Text("If you don't specify an amount, the installment will be marked as paid with the expected amount.")
                }
            }
            .navigationTitle("Register Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        registerPayment()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func registerPayment() {
        let paymentAmount = showingAmountField ? amount : installment.amount
        viewModel.registerPayment(
            for: debt,
            installmentNumber: installment.number,
            amount: paymentAmount
        )
    }
} 