import Foundation
import Combine

class DebtViewModel: ObservableObject {
    @Published var debts: [Debt] = []
    @Published var selectedFilter: DebtStatus?
    
    var filteredDebts: [Debt] {
        guard let filter = selectedFilter else { return debts }
        return debts.filter { $0.status == filter }
    }
    
    var totalDebtAmount: Double {
        debts.compactMap { $0.totalAmount }.reduce(0, +)
    }
    
    var activeDebtsCount: Int {
        debts.filter { $0.status == .pending }.count
    }
    
    var upcomingPaymentsCount: Int {
        debts.flatMap { $0.installments }
            .filter { !$0.isPaid && $0.dueDate > Date() }
            .count
    }
    
    func addDebt(_ debt: Debt) {
        debts.append(debt)
        // TODO: Implement cloud sync
    }
    
    func updateDebt(_ debt: Debt) {
        if let index = debts.firstIndex(where: { $0.id == debt.id }) {
            debts[index] = debt
            // TODO: Implement cloud sync
        }
    }
    
    func registerPayment(for debt: Debt, installmentNumber: Int, amount: Double?) {
        var updatedDebt = debt
        if var installment = updatedDebt.installments.first(where: { $0.number == installmentNumber }) {
            installment.paidAmount = amount
            installment.paidDate = Date()
            
            if let index = updatedDebt.installments.firstIndex(where: { $0.number == installmentNumber }) {
                updatedDebt.installments[index] = installment
            }
            
            // Update debt status if all installments are paid
            if updatedDebt.installments.allSatisfy(\.isPaid) {
                updatedDebt.status = .paid
            }
            
            updateDebt(updatedDebt)
        }
    }
} 