import Foundation
import Combine

//@MainActor
class DebtViewModel: ObservableObject {
    private let firebaseService: FirebaseService
    
    @Published var debts: [Debt] = []
    @Published var selectedFilter: DebtStatus?
    @Published var isLoadingDebts = false
    
    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
        setupListener()
    }
    
    private func setupListener() {
        firebaseService.syncDebts { [weak self] debts in
            self?.debts = debts
        }
    }
    
    var filteredDebts: [Debt] {
        guard let filter = selectedFilter else { return debts }
        return debts.filter { $0.status == filter }
    }
    
    var totalDebtAmount: Double {
        debts.reduce(0) { $0 + $1.totalAmount }
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
        firebaseService.saveDebt(debt)
    }
    
    func updateDebt(_ debt: Debt, with updates: (inout Debt) -> Void) {
        var updatedDebt = debt
        updates(&updatedDebt)
        updatedDebt.lastModified = Date()
        
        firebaseService.updateDebt(updatedDebt)
    }
    
    func deleteDebt(_ debt: Debt) {
        firebaseService.deleteDebt(id: debt.id)
    }
    
    func registerPayment(for debt: Debt, installmentNumber: Int, amount: Double?) {
        guard let index = debt.installments.firstIndex(where: { $0.number == installmentNumber }) else { return }
        
        var updatedDebt = debt
        updatedDebt.installments[index].paidAmount = amount ?? updatedDebt.installments[index].amount
        updatedDebt.installments[index].paidDate = Date()
        
        if updatedDebt.installments.allSatisfy(\.isPaid) {
            updatedDebt.status = .paid
        }
        
        updatedDebt.lastModified = Date()
        
        firebaseService.updateDebt(updatedDebt)
    }
    
    func undoPayment(for debt: Debt, installmentNumber: Int) {
        guard let index = debt.installments.firstIndex(where: { $0.number == installmentNumber }) else { return }
        
        var updatedDebt = debt
        updatedDebt.installments[index].paidAmount = nil
        updatedDebt.installments[index].paidDate = nil
        updatedDebt.status = .pending
        updatedDebt.lastModified = Date()
        
        firebaseService.updateDebt(updatedDebt)
    }
    
    func sortedDebts(by criteria: SortCriteria) -> [Debt] {
        switch criteria {
        case .creationDate:
            return debts.sorted { $0.creationDate < $1.creationDate }
        case .nextPaymentDate:
            return debts.sorted { ($0.nextPaymentDate ?? .distantFuture) < ($1.nextPaymentDate ?? .distantFuture) }
        case .progress:
            return debts.sorted { $0.progress > $1.progress }
        }
    }
    
    func reloadDebts() {
        isLoadingDebts = true

        firebaseService.syncDebts { [weak self] debts in
            DispatchQueue.main.async {
                self?.debts = debts
                self?.isLoadingDebts = false
            }
        }
    }
}

enum SortCriteria {
    case nextPaymentDate
    case progress
    case creationDate
}
