import SwiftUI

struct PaymentMethodsView: View {
    @ObservedObject var viewModel: IncomeViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(viewModel.paymentMethods) { method in
                    PaymentMethodCard(paymentMethod: method)
                        .contextMenu {
                            Button(role: .destructive) {
                                if let index = viewModel.paymentMethods.firstIndex(where: { $0.id == method.id }) {
                                    viewModel.deletePaymentMethod(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
        .frame(height: 200)
        .navigationTitle("Payment Methods")
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