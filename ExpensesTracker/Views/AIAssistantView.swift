import SwiftUI

struct AIAssistantView: View {
    @StateObject private var viewModel: AIAssistantViewModel
    
    init(
        expenseViewModel: ExpenseViewModel,
        incomeViewModel: IncomeViewModel,
        accountViewModel: AccountViewModel,
        debtViewModel: DebtViewModel
    ) {
        _viewModel = StateObject(wrappedValue: AIAssistantViewModel(
            expenseViewModel: expenseViewModel,
            incomeViewModel: incomeViewModel,
            accountViewModel: accountViewModel,
            debtViewModel: debtViewModel
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                    
                    if viewModel.isTyping {
                        TypingIndicator()
                    }
                }
                .padding()
            }
            
            // Input Area
            VStack(spacing: 0) {
                Divider()
                
                HStack {
                    TextField("Escribe tu pregunta...", text: $viewModel.inputMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isTyping)
                    
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                    }
                    .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("Asistente Financiero")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: viewModel.clearChat) {
                        Label("Limpiar Chat", systemImage: "trash")
                    }
                    
                    Button(action: viewModel.requestFinancialReport) {
                        Label("Generar Reporte", systemImage: "doc.text.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(message.isFromUser ? Color.blue : Color(.systemGray6))
                .foregroundColor(message.isFromUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser { Spacer() }
        }
    }
}

struct TypingIndicator: View {
    @State private var numberOfDots = 0
    
    var body: some View {
        HStack {
            Text("Escribiendo")
                .foregroundColor(.gray)
            + Text(String(repeating: ".", count: numberOfDots))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.leading)
        .onAppear {
            let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                numberOfDots = (numberOfDots + 1) % 4
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }
} 