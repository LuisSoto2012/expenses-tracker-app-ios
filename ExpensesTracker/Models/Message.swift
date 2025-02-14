import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let tokensUsed: Int
    
    init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date = Date(), tokensUsed: Int = 0) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.tokensUsed = tokensUsed
    }
} 