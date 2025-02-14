import SwiftUI
import Combine

class AIAssistantViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isTyping: Bool = false
    
    private let openAIService = OpenAIService()
    private let expenseViewModel: ExpenseViewModel
    
    init(expenseViewModel: ExpenseViewModel) {
        self.expenseViewModel = expenseViewModel
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: inputMessage, isFromUser: true)
        messages.append(userMessage)
        
        let userInput = inputMessage
        inputMessage = ""
        
        Task {
            isTyping = true
            
            do {
                // Preparar datos relevantes del usuario
                let userData = prepareUserData()
                
                // Obtener respuesta de OpenAI
                let response = try await openAIService.generateResponse(
                    messages: messages,
                    userData: userData
                )
                
                await MainActor.run {
                    messages.append(Message(content: response, isFromUser: false))
                    isTyping = false
                }
            } catch {
                await MainActor.run {
                    messages.append(Message(
                        content: "Lo siento, hubo un error al procesar tu pregunta.",
                        isFromUser: false
                    ))
                    isTyping = false
                }
            }
        }
    }
    
    func clearChat() {
        messages.removeAll()
    }
    
    private func prepareUserData() -> [String: Any] {
        // Obtener datos relevantes del ExpenseViewModel
        let currentDate = Date()
        let calendar = Calendar.current
        
        let monthlyExpenses = expenseViewModel.getMonthlyExpensesByCategory(for: currentDate)
        let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        let lastMonthExpenses = expenseViewModel.getMonthlyExpensesByCategory(for: lastMonthDate)
        
        return [
            "current_month_expenses": monthlyExpenses,
            "last_month_expenses": lastMonthExpenses,
            "total_monthly_expenses": expenseViewModel.totalMonthlyExpenses
        ]
    }
} 