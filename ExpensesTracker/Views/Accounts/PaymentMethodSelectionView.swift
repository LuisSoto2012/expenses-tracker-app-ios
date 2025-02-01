import SwiftUI

struct PaymentMethodSelectionView: View {
    @Binding var selectedPaymentMethods: [PaymentMethod] // Métodos de pago seleccionados
    @Binding var availablePaymentMethods: [PaymentMethod] // Métodos de pago disponibles

    // Usamos @Environment para acceder al modo de presentación
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Barra de título y botón de cerrar
            HStack {
                Text("Seleccionar Métodos de Pago")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    // Acción para cerrar la vista; esto debe ser manejado en la vista principal
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
                .padding(.trailing)
            }
            .padding(.top)
            
            Divider()
            
            // Lista de métodos de pago
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 15) {
                    ForEach(availablePaymentMethods) { method in
                        PaymentMethodCard(
                            paymentMethod: method,
                            isSelected: Binding(
                                get: {
                                    // Verifica si el método de pago está seleccionado
                                    selectedPaymentMethods.contains(where: { $0.id == method.id })
                                },
                                set: { _ in
                                    // No necesitamos hacer nada aquí, ya que el tap se maneja en el onTapGesture
                                }
                            )
                        )
                        .onTapGesture {
                            print("Método de pago seleccionado: \(method.name)")
                            // Lógica de selección/deselección
                            if let index = selectedPaymentMethods.firstIndex(where: { $0.id == method.id }) {
                                // Si ya está seleccionado, lo eliminamos
                                selectedPaymentMethods.remove(at: index)
                            } else {
                                // Si no está seleccionado, lo agregamos
                                selectedPaymentMethods.append(method)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
}
