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
    @StateObject private var expenseViewModel = ExpenseViewModel()
    @StateObject private var incomeViewModel = IncomeViewModel()
    @StateObject private var accountViewModel = AccountViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(expenseViewModel: expenseViewModel, incomeViewModel: incomeViewModel, accountViewModel: accountViewModel)
                .environmentObject(expenseViewModel)
        }
    }
}
