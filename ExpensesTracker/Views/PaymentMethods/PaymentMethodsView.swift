import SwiftUI

struct PaymentMethodsView: View {
    @ObservedObject var viewModel: IncomeViewModel
    @State private var paymentMethodToDelete: PaymentMethod?
    @State private var isHorizontal = true // Control de vista

    var body: some View {
        ScrollView { // Agregar ScrollView para que el contenido sea desplazable si es necesario
            VStack {
                // Selector para cambiar la vista entre horizontal y vertical
                Picker("Vista", selection: $isHorizontal) {
                    Text("Horizontal").tag(true)
                    Text("Vertical").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 300) // Ajustar el ancho del Picker
                .padding(.top, 20) // Ajustar el margen superior para evitar que quede tan cerca de la parte superior

                // Contenedor ScrollView con opción de orientación
                if isHorizontal {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            Spacer() // Agregar un Spacer antes de las tarjetas para centrar
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
                            Spacer() // Agregar un Spacer después de las tarjetas para centrar
                        }
                        .padding(.top, 80)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 20) {
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
                }
            }
            .navigationTitle("Métodos de Pago")
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
                    paymentMethodToDelete = nil
                }
                Button("Cancelar", role: .cancel) {}
            }, message: {
                Text("¿Estás seguro de eliminar este método de pago?")
            })
        }
    }
    
    private func deletePaymentMethod(_ method: PaymentMethod) {
        paymentMethodToDelete = method
    }
}

struct PaymentMethodCard: View {
    let paymentMethod: PaymentMethod
    @State private var isSelected = false // Estado de selección

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
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        paymentMethod.colorPrimary,
                        paymentMethod.colorSecondary
                    ]),
                    startPoint: paymentMethod.gradientStart,
                    endPoint: paymentMethod.gradientEnd
                )
                
                // Efecto de brillo / reflejo
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .blendMode(.overlay)
            }
        )
        .foregroundColor(.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .overlay(
            // Efecto de borde brillante animado
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: isSelected ?
                            [Color.white, Color.blue, Color.white] :
                            [Color.clear, Color.clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: isSelected ? 3 : 0
                )
                .opacity(isSelected ? 1 : 0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isSelected)
        )
        .onTapGesture {
            isSelected.toggle()
        }
    }
}
