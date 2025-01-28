import SwiftUI
import Combine

class IncomeViewModel: ObservableObject {
    @Published var incomes: [Income] = []
    @Published var paymentMethods: [PaymentMethod] = []
    
    @Published var showingAddIncome = false
    @Published var showingAddPaymentMethod = false
    
    private let defaults = UserDefaults.standard
    private let incomesKey = "savedIncomes"
    private let paymentMethodsKey = "savedPaymentMethods"
    
    init() {
        loadData()
    }
    
    func loadData() {
        if let data = defaults.data(forKey: incomesKey),
           let decoded = try? JSONDecoder().decode([Income].self, from: data) {
            incomes = decoded
        }
        
        if let data = defaults.data(forKey: paymentMethodsKey),
           let decoded = try? JSONDecoder().decode([PaymentMethod].self, from: data) {
            paymentMethods = decoded
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(incomes) {
            defaults.set(encoded, forKey: incomesKey)
        }
        
        if let encoded = try? JSONEncoder().encode(paymentMethods) {
            defaults.set(encoded, forKey: paymentMethodsKey)
        }
    }
    
    func addIncome(_ income: Income) {
        incomes.append(income)
        saveData()
    }
    
    func deleteIncome(at indexSet: IndexSet) {
        incomes.remove(atOffsets: indexSet)
        saveData()
    }
    
    func addPaymentMethod(_ paymentMethod: PaymentMethod) {
        paymentMethods.append(paymentMethod)
        saveData()
    }
    
    func deletePaymentMethod(at indexSet: IndexSet) {
        paymentMethods.remove(atOffsets: indexSet)
        saveData()
    }
    
    func calculateMonthlyIncome() -> Double {
        incomes.reduce(0) { total, income in
            guard let amount = income.amount else { return total }
            return total + (amount * income.frequency.multiplierForMonthly)
        }
    }
} 