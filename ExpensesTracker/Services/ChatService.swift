import Foundation
import FirebaseFirestore

class ChatService: ObservableObject {
    private let db = Firestore.firestore()
    private let deviceId: String
    
    init() {
        // Usar un identificador único por dispositivo
        if let existingId = UserDefaults.standard.string(forKey: "device_id") {
            self.deviceId = existingId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "device_id")
            self.deviceId = newId
        }
    }
    
    func saveMessage(_ message: Message) async throws {
        let messageData: [String: Any] = [
            "id": message.id.uuidString,
            "content": message.content,
            "isFromUser": message.isFromUser,
            "timestamp": message.timestamp,
            "tokensUsed": message.tokensUsed,
            "deviceId": deviceId
        ]
        
        try await db.collection("messages")
            .document(message.id.uuidString)
            .setData(messageData)
    }
    
    func loadMessages() async throws -> [Message] {
        let snapshot = try await db.collection("messages")
            .whereField("deviceId", isEqualTo: deviceId)
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Message? in
            let data = document.data()
            
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let content = data["content"] as? String,
                  let isFromUser = data["isFromUser"] as? Bool,
                  let timestamp = data["timestamp"] as? Timestamp else {
                return nil
            }
            
            let tokensUsed = data["tokensUsed"] as? Int ?? 0
            
            return Message(
                id: id,
                content: content,
                isFromUser: isFromUser,
                timestamp: timestamp.dateValue(),
                tokensUsed: tokensUsed
            )
        }
    }
    
    func clearChat() async throws {
        let snapshot = try await db.collection("messages")
            .whereField("deviceId", isEqualTo: deviceId)
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }
    
    func getTotalTokensUsed() async throws -> Int {
        let snapshot = try await db.collection("messages")
            .whereField("deviceId", isEqualTo: deviceId)
            .whereField("isFromUser", isEqualTo: false)
            .getDocuments()
        
        return snapshot.documents.reduce(0) { total, document in
            let tokensUsed = document.data()["tokensUsed"] as? Int ?? 0
            return total + tokensUsed
        }
    }
} 