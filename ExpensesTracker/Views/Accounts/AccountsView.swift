//
//  AccountsView.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 31/01/25.
//

import SwiftUI

struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var incomeViewModel = IncomeViewModel()
    @State private var showingAddAccount = false
    @State private var editingAccount: Account?

    var body: some View {
        NavigationView {
            List {
                ForEach(accountViewModel.accounts) { account in
                    AccountRow(account: account) {
                        editingAccount = account
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let account = accountViewModel.accounts[index]
                        accountViewModel.deleteAccount(account)
                    }
                }
            }
            .navigationTitle("Cuentas")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hecho") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddAccount = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AccountFormView(mode: .add, incomeViewModel: incomeViewModel)
        }
        .sheet(item: $editingAccount) { account in
            AccountFormView(mode: .edit(account), incomeViewModel: incomeViewModel)
        }
    }
}

