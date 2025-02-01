import SwiftUI
import Combine

class IncomeViewModel: ObservableObject {
    @Published var incomes: [Income] = []
    @Published var paymentMethods: [PaymentMethod] = []
    
    @Published var showingAddIncome = false
    @Published var showingAddPaymentMethod = false
    
    private let firebaseService = FirebaseService.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        firebaseService.syncIncomes { [weak self] incomes in
            self?.incomes = incomes
        }
        
        firebaseService.syncPaymentMethods { [weak self] paymentMethods in
            self?.paymentMethods = paymentMethods
            print("Métodos de pago sincronizados: \(paymentMethods)")
        }
    }
    
    func addIncome(_ income: Income) {
        firebaseService.saveIncome(income)
    }
    
    func deleteIncome(at indexSet: IndexSet) {
        indexSet.forEach { index in
            let income = incomes[index]
            firebaseService.deleteIncome(id: income.id)
        }
    }
    
    func addPaymentMethod(_ paymentMethod: PaymentMethod) {
        firebaseService.savePaymentMethod(paymentMethod)
    }
    
    func deletePaymentMethod(at indexSet: IndexSet) {
        indexSet.forEach { index in
            let paymentMethod = paymentMethods[index]
            // Eliminar de Firestore
            firebaseService.deletePaymentMethod(id: paymentMethod.id)
            // Eliminar de la lista local
            paymentMethods.remove(at: index)
        }
    }
    
    func calculateMonthlyIncome() -> Double {
        incomes.reduce(0) { total, income in
            guard let amount = income.amount else { return total }
            return total + (amount * income.frequency.multiplierForMonthly)
        }
    }
}
