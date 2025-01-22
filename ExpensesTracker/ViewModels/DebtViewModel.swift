import Foundation
import Combine

@MainActor
class DebtViewModel: ObservableObject {
    private let firebaseService: FirebaseService
    
    @Published var debts: [Debt] = []
    @Published var selectedFilter: DebtStatus?
    
    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
        setupListener()
    }
    
    private func setupListener() {
        firebaseService.observeDebts { [weak self] debts in
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
        Task {
            do {
                try await firebaseService.addDebt(debt)
            } catch {
                print("Error adding debt: \(error)")
            }
        }
    }
    
    func updateDebt(_ debt: Debt, with updates: (inout Debt) -> Void) {
        var updatedDebt = debt
        updates(&updatedDebt)
        updatedDebt.lastModified = Date()
        
        Task {
            do {
                try await firebaseService.updateDebt(updatedDebt)
            } catch {
                print("Error updating debt: \(error)")
            }
        }
    }
    
    func deleteDebt(_ debt: Debt) {
        Task {
            do {
                try await firebaseService.deleteDebt(debt)
            } catch {
                print("Error deleting debt: \(error)")
            }
        }
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
        
        Task {
            do {
                try await firebaseService.updateDebt(updatedDebt)
            } catch {
                print("Error registering payment: \(error)")
            }
        }
    }
    
    func undoPayment(for debt: Debt, installmentNumber: Int) {
        guard let index = debt.installments.firstIndex(where: { $0.number == installmentNumber }) else { return }
        
        var updatedDebt = debt
        updatedDebt.installments[index].paidAmount = nil
        updatedDebt.installments[index].paidDate = nil
        updatedDebt.status = .pending
        updatedDebt.lastModified = Date()
        
        Task {
            do {
                try await firebaseService.updateDebt(updatedDebt)
            } catch {
                print("Error undoing payment: \(error)")
            }
        }
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
}

enum SortCriteria {
    case nextPaymentDate
    case progress
    case creationDate
}
