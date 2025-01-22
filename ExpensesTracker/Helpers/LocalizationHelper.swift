import Foundation
import SwiftUI

extension View {
    func localized() -> some View {
        let languageManager = LanguageManager.shared
        return self
            .environment(\.locale, .init(identifier: languageManager.currentLanguage.rawValue))
            .id(languageManager.refreshID) // Force view refresh when language changes
    }
}

extension String {
    func localized() -> String {
        return LanguageManager.localizedString(for: self)
    }
} 