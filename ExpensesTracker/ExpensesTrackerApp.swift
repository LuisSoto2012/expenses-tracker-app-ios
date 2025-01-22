//
//  ExpensesTrackerApp.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 17/01/25.
//

import SwiftUI
import FirebaseCore

@main
struct ExpenseTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var expenseViewModel = ExpenseViewModel()
    @StateObject private var languageManager = LanguageManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(expenseViewModel: expenseViewModel) // Aquí se pasa la instancia
                .environmentObject(expenseViewModel)
                .environment(\.locale, .init(identifier: languageManager.currentLanguage.rawValue))
                .id(languageManager.refreshID) // Force view refresh when language changes
        }
    }
}
