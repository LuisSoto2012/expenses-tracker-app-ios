import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language {
        didSet {
            // Save language to UserDefaults
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            
            // Force update the bundle
            if let languageBundlePath = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
               let languageBundle = Bundle(path: languageBundlePath) {
                Self.currentBundle = languageBundle
            }
            
            // Force UI refresh
            refreshUI()
        }
    }
    
    private static var currentBundle: Bundle?
    @Published private(set) var refreshID = UUID()
    
    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            }
        }
    }
    
    private init() {
        // Get saved language or use device language as default
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            currentLanguage = Language(rawValue: savedLanguage) ?? .english
        } else {
            let preferredLanguage = Bundle.main.preferredLocalizations.first ?? "en"
            currentLanguage = Language(rawValue: preferredLanguage) ?? .english
        }
        
        // Initialize the bundle
        if let languageBundlePath = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let languageBundle = Bundle(path: languageBundlePath) {
            Self.currentBundle = languageBundle
        }
    }
    
    func setLanguage(_ language: Language) {
        guard language != currentLanguage else { return }
        currentLanguage = language
    }
    
    static func localizedString(for key: String) -> String {
        return currentBundle?.localizedString(forKey: key, value: nil, table: nil) 
            ?? Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
    
    private func refreshUI() {
        refreshID = UUID()
    }
}

// Extension to help with bundle localization
extension Bundle {
    func localize(language: String) {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return
        }
        
        objc_setAssociatedObject(self, &AssociatedKeys.bundle, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private struct AssociatedKeys {
    static var bundle = 0
}

