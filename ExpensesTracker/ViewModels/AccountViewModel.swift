//
//  AccountViewModel.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 31/01/25.
//

import SwiftUI
import Combine

class AccountViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    
    private let firebaseService = FirebaseService()
    
    init() {
        setupDataSync()
    }
    
    private func setupDataSync() {
        isLoading = true
        
        // Sincronizar cuentas
        firebaseService.syncAccounts { [weak self] accounts in
            self?.accounts = accounts
            self?.isLoading = false
        }
    }
    
    // MARK: - Account Methods
    
    func addAccount(_ account: Account) {
        firebaseService.saveAccount(account)
    }
    
    func updateAccount(_ account: Account) {
        firebaseService.updateAccount(account)
    }
    
    func deleteAccount(_ account: Account) {
        firebaseService.deleteAccount(id: account.id)
    }
    
    func reloadAccounts() {
        isLoading = true
        
        firebaseService.syncAccounts { [weak self] accounts in
            DispatchQueue.main.async {
                self?.accounts = accounts
                self?.isLoading = false
            }
        }
    }
    
    func registerExpense(_ expense: Expense) {
        guard let paymentMethodId = expense.paymentMethodId else { return }

        // Buscar la cuenta asociada a este método de pago
        if let account = accounts.first(where: { $0.paymentMethods.contains(paymentMethodId) }) {
            
            // Crear una transacción
            let transaction = Transaction(
                id: UUID(),
                amount: -expense.amount, // Restamos el gasto
                date: expense.date,
                description: expense.name,
                paymentMethodId: paymentMethodId,
                accountId: account.id
            )
            
            // Guardar la transacción en Firestore
            firebaseService.saveTransaction(transaction)
            
            // Calcular nuevo balance basado en transacciones
            updateAccountBalance(accountId: account.id)
        }
    }

    func updateAccountBalance(accountId: UUID) {
        firebaseService.fetchTransactions(for: accountId) { [weak self] transactions in
            guard let self = self,
                  let accountIndex = self.accounts.firstIndex(where: { $0.id == accountId }) else { return }
            
            // Recalcular balance
            let newBalance = self.accounts[accountIndex].initialBalance + transactions.reduce(0) { $0 + $1.amount }
            
            // Actualizar cuenta
            self.accounts[accountIndex].balance = newBalance
            self.firebaseService.updateAccount(self.accounts[accountIndex])
        }
    }
    
    // MARK: - Helper Methods
    
    func getAccountById(_ id: UUID) -> Account? {
        return accounts.first { $0.id == id }
    }
    
    func getAccountsSortedByName() -> [Account] {
        return accounts.sorted { $0.name < $1.name }
    }
}
