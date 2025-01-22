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
                    Label("Inicio", systemImage: "house.fill") // Translated text
                }
            
            ExpensesView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label("Gastos", systemImage: "dollarsign.circle.fill") // Translated text
                }
            
            DebtDashboardView()
                .tabItem {
                    Label("Deudas", systemImage: "creditcard.fill") // Translated text
                }
            
            DashboardView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label("Estadísticas", systemImage: "chart.pie.fill") // Translated text
                }
            
            SettingsView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label("Configuración", systemImage: "gear") // Translated text
                }
        }
        .onChange(of: expenseViewModel.expenses) { _ in
            checkBudgetAlerts()
        }
        .alert("Alerta de presupuesto", isPresented: $showingBudgetAlert) { // Translated text
            Button("Aceptar", role: .cancel) { } // Translated text
        } message: {
            if let category = budgetAlertCategory {
                Text("Has excedido tu presupuesto para \(category.name)") // Translated text
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
