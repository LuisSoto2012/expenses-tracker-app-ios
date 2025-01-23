import SwiftUI
import ConfettiView

struct DebtDetailView: View {
    let debt: Debt
    @ObservedObject var viewModel: DebtViewModel
    @ObservedObject var expenseViewModel: ExpenseViewModel
    @State private var showingPaymentSheet = false
    @State private var selectedInstallment: DebtInstallment?
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
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
                        viewModel: viewModel,
                        expenseViewModel: expenseViewModel
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditSheet = true }) {
                            Label("Editar Deuda", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Eliminar Deuda", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Eliminar Deuda", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Eliminar", role: .destructive) {
                    viewModel.deleteDebt(debt)
                    dismiss()
                }
            } message: {
                Text("¿Estás seguro de que quieres eliminar esta deuda? Esta acción no se puede deshacer.")
            }
            .sheet(isPresented: $showingEditSheet) {
                EditDebtView(debt: debt, viewModel: viewModel)
            }
            
            // Overlay de ConfettiView
            ConfettiView(isPresented: $showConfetti)
                .frame(width: 200, height: 200) // Ajusta el tamaño según lo necesites
                .transition(.opacity)
                .onChange(of: debt.status) { newValue in
                    if newValue == .paid {
                        showConfetti = true
                    }
                }
                .onAppear {
                    // Verificar si el estado de la deuda es 'pagado' al entrar a la vista
                    if debt.status == .paid {
                        showConfetti = true
                    }
                }
                .zIndex(1)  // Asegúrate de que el ConfettiView esté encima
        }
    }

    
    private var debtInfoSection: some View {
        Section("Información de la Deuda") {
            LabeledContent("Monto Total") {
               Text(debt.totalAmount.formatted(.currency(code: "PEN")))
           }

           LabeledContent("Restante") {
               Text(debt.remainingAmount.formatted(.currency(code: "PEN")))
           }
            
            LabeledContent("Estado") {
                StatusBadge(status: debt.status)
            }
            
            LabeledContent("Progreso") {
                Text("\(Int(debt.progress * 100))%")
            }
            
            if let nextPaymentDate = debt.nextPaymentDate {
                LabeledContent("Próximo Pago") {
                    Text(nextPaymentDate, style: .date)
                }
            }
            
            if let description = debt.description {
                LabeledContent("Descripción") {
                    Text(description)
                }
            }
            
            LabeledContent("Compartido") {
                Text(debt.sharedWithPartner ? "Sí" : "No")
            }
        }
    }
    
    private var installmentsSection: some View {
        Section("Cuotas") {
            ForEach(debt.installments) { installment in
                InstallmentRow(installment: installment, debt: debt, viewModel: viewModel)
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
    let debt: Debt
    @ObservedObject var viewModel: DebtViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Cuota #\(installment.number)")
                    .font(.headline)
                Spacer()
                if installment.isPaid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Fecha de Vencimiento")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(installment.dueDate.formatted(date: .abbreviated, time: .omitted))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Monto")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(installment.amount.formatted(.currency(code: "PEN")))
                }
            }
            
            if installment.isPaid {
                HStack {
                    Text("Pagada")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let paidAmount = installment.paidAmount {
                        Text(paidAmount.formatted(.currency(code: "PEN")))
                    }
                    if let paidDate = installment.paidDate {
                        Text("el \(paidDate.formatted(date: .abbreviated, time: .omitted))")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.undoPayment(for: debt, installmentNumber: installment.number)
                    }) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .foregroundColor(.blue)
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
    @ObservedObject var expenseViewModel: ExpenseViewModel
    
    @State private var amount: Double?
    @State private var showingAmountField = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Especificar monto de pago", isOn: $showingAmountField)
                    
                    if showingAmountField {
                        TextField("Monto", value: $amount, format: .currency(code: "PEN"))
                            .keyboardType(.decimalPad)
                    }
                } footer: {
                    Text("Si no especificas un monto, la cuota se marcará como pagada con el monto esperado.")
                }
            }
            .navigationTitle("Registrar Pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        registerPayment()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func registerPayment() {
        let paymentAmount = (showingAmountField ? amount : installment.amount) ?? 0.0
        
        // Comprobamos si categoryId está presente
        guard let categoryId = debt.categoryId else {
            print("Error: El categoryId de la deuda es nulo.")
            return
        }
        
        // Crear un gasto asociado al pago
        let expense = Expense(
            id: UUID(),
            amount: paymentAmount,
            date: Date(),
            notes: "Pago de deuda: \(debt.name) - Cuota \(installment.number)",
            categoryId: categoryId // Aquí ya garantizamos que categoryId no es nulo
        )
        
        // Llamamos a addExpense una sola vez y guardamos el expenseId
        if let expenseId = expenseViewModel.addExpense(expense) {
            // Ahora pasamos el expenseId a registerPayment
            viewModel.registerPayment(
                for: debt,
                installmentNumber: installment.number,
                amount: paymentAmount,
                expenseId: expenseId  // Pasamos el ID aquí
            )
        } else {
            print("No se pudo guardar el gasto.")
        }
    }
}
