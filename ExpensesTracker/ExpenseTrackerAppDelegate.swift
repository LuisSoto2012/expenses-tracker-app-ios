import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // Agregar referencia al ExpenseViewModel
    private var expenseViewModel: ExpenseViewModel?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Método para configurar el ViewModel
    func configure(with expenseViewModel: ExpenseViewModel) {
        self.expenseViewModel = expenseViewModel
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func application(_ application: UIApplication, didBecomeActive: UIApplication) {
        expenseViewModel?.checkAutomaticPayments()
    }
} 
