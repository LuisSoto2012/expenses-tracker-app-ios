import SwiftUI

struct PaymentMethodsView: View {
    @ObservedObject var viewModel: IncomeViewModel
    @State private var paymentMethodToDelete: PaymentMethod?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(viewModel.paymentMethods) { method in
                    PaymentMethodCard(paymentMethod: method)
                        .contextMenu {
                            Button(role: .destructive) {
                                deletePaymentMethod(method)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
        .frame(height: 200)
        .navigationTitle("Metodos de Pago")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showingAddPaymentMethod = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddPaymentMethod) {
            AddPaymentMethodView(viewModel: viewModel)
        }
        .confirmationDialog("Eliminar Metodo de Pago", isPresented: Binding(
            get: { paymentMethodToDelete != nil },
            set: { _ in paymentMethodToDelete = nil }
        ), actions: {
            Button("Eliminar", role: .destructive) {
                if let method = paymentMethodToDelete,
                   let index = viewModel.paymentMethods.firstIndex(where: { $0.id == method.id }) {
                    viewModel.deletePaymentMethod(at: IndexSet(integer: index))
                }
                paymentMethodToDelete = nil // Limpiar el estado después de eliminar
            }
            Button("Cancelar", role: .cancel) {}
        }, message: {
            Text("¿Estas seguro de eliminar este metodo de pago?")
        })
    }
    
    private func deletePaymentMethod(_ method: PaymentMethod) {
        paymentMethodToDelete = method
    }
}

struct PaymentMethodCard: View {
    let paymentMethod: PaymentMethod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: paymentMethod.type.icon)
                Spacer()
                if paymentMethod.isDefault {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            if let lastFour = paymentMethod.lastFourDigits {
                Text("**** **** **** \(lastFour)")
                    .font(.system(.body, design: .monospaced))
            }
            
            Text(paymentMethod.name)
                .font(.headline)
            
            if let expiry = paymentMethod.expiryDate {
                Text(expiry, style: .date)
                    .font(.caption)
            }
        }
        .padding()
        .frame(width: 300, height: 180)
        .background(paymentMethod.color)
        .foregroundColor(.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
