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
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(expenseViewModel: expenseViewModel)
                .environmentObject(expenseViewModel)
        }
    }
}
