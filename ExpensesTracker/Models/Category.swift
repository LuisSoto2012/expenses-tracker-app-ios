import Foundation
import SwiftUI

struct Category: Identifiable, Codable {
    let id: UUID
    var name: String
    var color: String // Store color as hex string
    var icon: String // SF Symbol name
    var budget: Double? // Optional default budget
    
    init(id: UUID = UUID(), name: String, color: String, icon: String, budget: Double? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.budget = budget
    }
    
    var uiColor: Color {
        Color(hex: color) ?? .blue
    }
}

// Default categories
extension Category {
    static let defaults: [Category] = [
        Category(name: "Food", color: "#FF6B6B", icon: "cart.fill", budget: 500),
        Category(name: "Transportation", color: "#4ECDC4", icon: "car.fill", budget: 200),
        Category(name: "Entertainment", color: "#45B7D1", icon: "tv.fill", budget: 150),
        Category(name: "Shopping", color: "#96CEB4", icon: "bag.fill", budget: 300),
        Category(name: "Utilities", color: "#D4A373", icon: "bolt.fill", budget: 200),
        Category(name: "Rent", color: "#264653", icon: "house.fill", budget: 1200)
    ]
} 