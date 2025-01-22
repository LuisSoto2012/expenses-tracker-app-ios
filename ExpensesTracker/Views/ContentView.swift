//
//  ContentView.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 17/01/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var expenseViewModel: ExpenseViewModel
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showingBudgetAlert = false
    @State private var budgetAlertCategory: Category?
    
    // Esto fuerza a la vista a recrearse cuando cambia el idioma
    @State private var languageUpdateTrigger = UUID()
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label(String(localized: "home"), systemImage: "house.fill")
                }
            
            ExpensesView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label(String(localized: "expenses"), systemImage: "dollarsign.circle.fill")
                }
            
            DebtDashboardView()
                .tabItem {
                    Label(String(localized: "debts"), systemImage: "creditcard.fill")
                }
            
            DashboardView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label(String(localized: "dashboard"), systemImage: "chart.pie.fill")
                }
            
            SettingsView()
                .environmentObject(expenseViewModel)
                .tabItem {
                    Label(String(localized: "settings"), systemImage: "gear")
                }
        }
        .id(languageUpdateTrigger) // Esto fuerza la recreación de la vista
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            // Actualizar el trigger para forzar la recreación de la vista
            languageUpdateTrigger = UUID()
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
