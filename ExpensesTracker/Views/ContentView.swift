//
//  ContentView.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 17/01/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var expenseViewModel: ExpenseViewModel
    @State private var showingBudgetAlert = false
    @State private var budgetAlertCategory: Category?
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            ExpensesView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label("Expenses", systemImage: "dollarsign.circle.fill")
                }
            
            DebtDashboardView()
                .tabItem {
                    Label("Debts", systemImage: "creditcard.fill")
                }
            
            DashboardView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
            
            SettingsView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onChange(of: expenseViewModel.expenses) { _ in
            checkBudgetAlerts()
        }
        .alert("Budget Alert", isPresented: $showingBudgetAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let category = budgetAlertCategory {
                Text("You've exceeded your budget for \(category.name)")
            }
        }
    }
    
    private func checkBudgetAlerts() {
        let currentDate = Date()
        for category in expenseViewModel.categories {
            let progress = expenseViewModel.getBudgetProgress(for: category.id, month: currentDate)
            if progress > 1.0 {
                budgetAlertCategory = category
                showingBudgetAlert = true
                break
            }
        }
    }
}
