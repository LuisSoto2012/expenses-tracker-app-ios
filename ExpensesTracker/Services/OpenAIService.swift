import Foundation

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // En producción, esto debería obtenerse de forma segura
        self.apiKey = "API_KEY"
    }
    
    func generateResponse(messages: [Message], userData: [String: Any]) async throws -> String {
        var requestMessages: [[String: Any]] = []
        
        // Sistema prompt inicial con contexto
        let systemPrompt = """
        You are a financial assistant. You have access to the user's financial data. 
        Provide helpful insights and advice based on their spending patterns.
        Be concise, friendly, and specific in your responses.
        """
        
        requestMessages.append([
            "role": "system",
            "content": systemPrompt
        ])
        
        // Agregar contexto de datos del usuario
        let userContext = """
        User's financial data:
        \(userData)
        """
        
        requestMessages.append([
            "role": "system",
            "content": userContext
        ])
        
        // Agregar mensajes previos
        for message in messages {
            requestMessages.append([
                "role": message.isFromUser ? "user" : "assistant",
                "content": message.content
            ])
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": requestMessages,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        return response.choices.first?.message.content ?? "Lo siento, no pude procesar tu pregunta."
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: ChatMessage
}

struct ChatMessage: Codable {
    let content: String
} 
