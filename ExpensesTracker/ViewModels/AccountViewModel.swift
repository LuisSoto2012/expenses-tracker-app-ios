//
//  AccountViewModel.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 31/01/25.
//

import SwiftUI
import Combine
import FirebaseFirestore

class AccountViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    
    private let firebaseService = FirebaseService()
    
    init() {
        setupDataSync()
    }
    
    private func setupDataSync() {
        isLoading = true
        
        // Sincronizar cuentas con listener
        firebaseService.syncAccounts { [weak self] accounts in
            DispatchQueue.main.async {
                self?.accounts = accounts
                self?.isLoading = false
            }
        }
        
        // Sincronizar transacciones con listener
        firebaseService.syncTransactions { [weak self] transactions in
            DispatchQueue.main.async {
                self?.transactions = transactions
                self?.updateAccountBalances()
            }
        }
    }
    
    // MARK: - Account Methods
    
    func addAccount(_ account: Account) {
        firebaseService.saveAccount(account)
        // Opcionalmente, actualizar la lista local inmediatamente
        DispatchQueue.main.async { [weak self] in
            self?.accounts.append(account)
            self?.objectWillChange.send()
        }
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
        guard let defaultAccount = accounts.first(where: { $0.isDefault }) ?? accounts.first else {
            return
        }
        
        // Verificar si ya existe una transacción para este gasto
        if transactions.contains(where: { $0.expenseId == expense.id }) {
            return  // Si ya existe una transacción para este gasto, no crear otra
        }
        
        let transaction = Transaction(
            id: UUID(),
            expenseId: expense.id,
            accountId: defaultAccount.id,
            amount: expense.amount,
            type: expense.isRecurring ? .debt : .expense,
            date: expense.date,
            description: expense.name,
            category: expense.categoryId
        )
        
        addTransaction(transaction)
    }

    func updateAccountBalance(accountId: UUID) {
        firebaseService.fetchTransactions(for: accountId) { [weak self] transactions in
            guard let self = self,
                  let accountIndex = self.accounts.firstIndex(where: { $0.id == accountId }) else { return }
            
            // Recalcular balance
            let newBalance = self.accounts[accountIndex].initialBalance + transactions.reduce(0) { $0 + $1.amount }
            
            // Actualizar cuenta
            self.accounts[accountIndex].currentBalance = newBalance
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
    
    func addTransaction(_ transaction: Transaction) {
        // Verificar si ya existe una transacción con el mismo expenseId
        if let expenseId = transaction.expenseId,
           transactions.contains(where: { $0.expenseId == expenseId }) {
            return  // Si ya existe, no agregar otra
        }
        
        // Guardar la transacción en Firebase
        firebaseService.saveTransaction(transaction)
        
        // Actualizar la lista local de transacciones
        DispatchQueue.main.async { [weak self] in
            self?.transactions.append(transaction)
            self?.updateAccountBalances()
            self?.objectWillChange.send()
        }
    }
    
    func getTransactions(for accountId: UUID) -> [Transaction] {
        return transactions
            .filter { $0.accountId == accountId }
            .sorted { $0.date > $1.date }
    }
    
    func syncTransactions() {
        isLoading = true
        
        // Fetch all expenses from Firebase
        firebaseService.syncExpenses { [weak self] expenses in
            guard let self = self else { return }
            
            // Get existing transaction expense IDs
            let existingTransactionExpenseIds = Set(self.transactions.compactMap { $0.expenseId })
            
            // Filter expenses that do not have transactions
            let expensesWithoutTransactions = expenses.filter { expense in
                !existingTransactionExpenseIds.contains(expense.id)
            }
            
            // If no default account, use the first account
            guard let defaultAccount = self.accounts.first(where: { $0.isDefault }) ?? self.accounts.first else {
                self.isLoading = false
                return
            }
            
            // Create transactions for each expense without a transaction
            for expense in expensesWithoutTransactions {
                // Verificar una vez más antes de crear la transacción
                if !self.transactions.contains(where: { $0.expenseId == expense.id }) {
                    let transaction = Transaction(
                        id: UUID(),
                        expenseId: expense.id,
                        accountId: defaultAccount.id,
                        amount: expense.amount,
                        type: expense.isRecurring ? .debt : .expense,
                        date: expense.date,
                        description: expense.name,
                        category: expense.categoryId
                    )
                    self.addTransaction(transaction)
                }
            }
            
            self.isLoading = false
            self.updateAccountBalances()
        }
    }
    
    private func updateAccountBalances() {
        for (index, account) in accounts.enumerated() {
            var balance = account.initialBalance
            
            // Filtrar transacciones para esta cuenta
            let accountTransactions = transactions.filter { $0.accountId == account.id }
            
            // Calcular el balance basado en las transacciones
            for transaction in accountTransactions {
                switch transaction.type {
                case .income:
                    balance += transaction.amount
                case .expense, .debt:
                    balance -= transaction.amount
                }
            }
            
            // Actualizar el balance de la cuenta
            DispatchQueue.main.async { [weak self] in
                var updatedAccount = account
                updatedAccount.currentBalance = balance
                self?.accounts[index] = updatedAccount
                
                // Guardar en Firebase
                self?.firebaseService.saveAccount(updatedAccount)
            }
        }
    }
}
