//
//  ExpensesTrackerApp.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 17/01/25.
//

import SwiftUI
import FirebaseCore

@main
struct ExpensesTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    // Wrap ViewModels in StateObjects
    @StateObject private var accountViewModel: AccountViewModel
    @StateObject private var expenseViewModel: ExpenseViewModel
    @StateObject private var incomeViewModel: IncomeViewModel
    @StateObject private var debtViewModel: DebtViewModel
    
    init() {
        // Configure Firebase with custom plist for the test environment
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info-test", ofType: "plist") {
            let options = FirebaseOptions(contentsOfFile: filePath)
            FirebaseApp.configure(options: options!)
        } else {
            FirebaseApp.configure()
            print("No se encontró el archivo de configuración de Firebase para el entorno de pruebas.")
        }
        
        // Initialize ViewModels using factory
        let factory = ViewModelFactory.shared
        _accountViewModel = StateObject(wrappedValue: factory.accountViewModel)
        _expenseViewModel = StateObject(wrappedValue: factory.expenseViewModel)
        _incomeViewModel = StateObject(wrappedValue: factory.incomeViewModel)
        _debtViewModel = StateObject(wrappedValue: factory.debtViewModel)
        
        // Configurar el AppDelegate con el ExpenseViewModel
        appDelegate.configure(with: expenseViewModel)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                expenseViewModel: expenseViewModel,
                incomeViewModel: incomeViewModel,
                accountViewModel: accountViewModel,
                debtViewModel: debtViewModel
            )
            .environmentObject(expenseViewModel)
            .environmentObject(accountViewModel)
            .environmentObject(incomeViewModel)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                expenseViewModel.checkAutomaticPayments()
            }
        }
    }
}
