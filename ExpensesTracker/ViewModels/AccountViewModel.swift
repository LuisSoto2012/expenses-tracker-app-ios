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
    
    // MARK: - Helper Methods
    
    func getAccountById(_ id: UUID) -> Account? {
        return accounts.first { $0.id == id }
    }
    
    func getAccountsSortedByName() -> [Account] {
        return accounts.sorted { $0.name < $1.name }
    }
}
