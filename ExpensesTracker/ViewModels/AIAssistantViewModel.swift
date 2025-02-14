import SwiftUI
import Combine

class AIAssistantViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isTyping: Bool = false
    
    private let openAIService: OpenAIService
    private let chatService: ChatService
    private let expenseViewModel: ExpenseViewModel
    private let incomeViewModel: IncomeViewModel
    private let accountViewModel: AccountViewModel
    private let debtViewModel: DebtViewModel
    
    // UserDefaults keys
    private let messagesKey = "ai_chat_messages"
    private let tokensUsedKey = "ai_tokens_used"
    
    init(
        expenseViewModel: ExpenseViewModel,
        incomeViewModel: IncomeViewModel,
        accountViewModel: AccountViewModel,
        debtViewModel: DebtViewModel
    ) {
        self.openAIService = OpenAIService()
        self.chatService = ChatService()
        self.expenseViewModel = expenseViewModel
        self.incomeViewModel = incomeViewModel
        self.accountViewModel = accountViewModel
        self.debtViewModel = debtViewModel
    }
    
    @MainActor
    func initialLoad() async {
        do {
            let loadedMessages = try await chatService.loadMessages()
            messages = loadedMessages
            
            // Cargar tokens usados
            let tokensUsed = loadedMessages.reduce(0) { $0 + $1.tokensUsed }
            openAIService.totalTokensUsed = tokensUsed
        } catch {
            print("Error loading messages: \(error)")
        }
    }
    
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: messagesKey)
        }
        UserDefaults.standard.set(openAIService.totalTokensUsed, forKey: tokensUsedKey)
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: inputMessage, isFromUser: true)
        messages.append(userMessage)
        inputMessage = ""
        isTyping = true
        
        // Guardar mensaje del usuario
        Task {
            try? await chatService.saveMessage(userMessage)
            
            do {
                let userData = prepareUserData()
                let (response, tokensUsed) = try await openAIService.generateResponse(
                    messages: messages,
                    userData: userData
                )
                
                await MainActor.run {
                    let assistantMessage = Message(
                        content: response,
                        isFromUser: false,
                        tokensUsed: tokensUsed
                    )
                    messages.append(assistantMessage)
                    isTyping = false
                    
                    // Guardar mensaje del asistente
                    Task {
                        try? await chatService.saveMessage(assistantMessage)
                    }
                }
            } catch {
                await MainActor.run {
                    let errorMessage = Message(
                        content: "Lo siento, hubo un error al procesar tu mensaje.",
                        isFromUser: false
                    )
                    messages.append(errorMessage)
                    isTyping = false
                    
                    // Guardar mensaje de error
                    Task {
                        try? await chatService.saveMessage(errorMessage)
                    }
                }
            }
        }
    }
    
    func clearChat() {
        Task {
            try? await chatService.clearChat()
            await MainActor.run {
                messages.removeAll()
            }
        }
        saveMessages()
    }
    
    private func prepareUserData() -> [String: Any] {
        let currentDate = Date()
        let calendar = Calendar.current
        let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        let lastWeekDate = calendar.date(byAdding: .day, value: -7, to: currentDate)!
        
        // Formatear números para mejor legibilidad
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale(identifier: "es_PE")
        
        // 1. Datos de Cuentas
        let accounts = accountViewModel.accounts.map { account -> [String: Any] in
            [
                "name": account.name,
                "balance": account.currentBalance,
                "type": account.type,
                "payment_methods": account.paymentMethods.compactMap { methodId in
                    incomeViewModel.paymentMethods.first { $0.id == methodId }?.name
                },
                "is_primary": account.isDefault,
                //"last_transaction_date": account.lastTransactionDate ?? currentDate
            ]
        }
        
        let totalBalance = accountViewModel.accounts.reduce(0) { $0 + $1.currentBalance }
        
        // 1. Datos de Gastos
        let currentMonthExpenses = expenseViewModel.getMonthlyExpensesByCategory(for: currentDate)
            .map { category, amount in
                [
                    "category": category.name,
                    "amount": amount,
                    "budget": expenseViewModel.getBudget(for: category.id, month: currentDate)?.amount ?? 0,
                    "progress": expenseViewModel.getBudgetProgress(for: category.id, month: currentDate),
                    "expenses": expenseViewModel.expenses
                        .filter { expense in
                            expense.categoryId == category.id &&
                            calendar.isDate(expense.date, equalTo: currentDate, toGranularity: .month)
                        }
                        .map { expense in
                            [
                                "name": expense.name,
                                "amount": expense.amount,
                                "date": expense.date,
                                "is_recurring": expense.isRecurring,
                                "is_paid": expense.isPaid ?? false,
                                "notes": expense.notes ?? ""
                            ]
                        }
                ]
            }
        
        let lastMonthExpenses = expenseViewModel.getMonthlyExpensesByCategory(for: lastMonthDate)
            .map { category, amount in
                [
                    "category": category.name,
                    "amount": amount,
                    "expenses": expenseViewModel.expenses
                        .filter { expense in
                            expense.categoryId == category.id &&
                            calendar.isDate(expense.date, equalTo: lastMonthDate, toGranularity: .month)
                        }
                        .map { expense in
                            [
                                "name": expense.name,
                                "amount": expense.amount,
                                "date": expense.date,
                                "is_recurring": expense.isRecurring,
                                "is_paid": expense.isPaid ?? false,
                                "notes": expense.notes ?? ""
                            ]
                        }
                ]
            }
        
        // 2. Datos de Ingresos
        let monthlyIncome = incomeViewModel.calculateMonthlyIncome()
        let paymentMethods = incomeViewModel.paymentMethods.map { method in
            ["name": method.name, "type": method.type]
        }
        
        // 3. Datos de Gastos Recurrentes
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        let recurringExpenses = expenseViewModel.getRecurringExpenses(forMonth: currentMonth, year: currentYear)
            .map { expense in
                [
                    "name": expense.name,
                    "amount": expense.amount,
                    "isPaid": expense.isPaid ?? false,
                    "category": expenseViewModel.categories.first { $0.id == expense.categoryId }?.name ?? "Sin categoría"
                ]
            }
        
        // 4. Análisis de Tendencias
        let monthlyTotals = expenseViewModel.getMonthlyTotalExpenses(for: 3)
            .map { date, amount in
                [
                    "month": calendar.component(.month, from: date),
                    "amount": amount
                ]
            }
        
        // 5. Datos de Presupuestos
        let budgets = expenseViewModel.categories.compactMap { category -> [String: Any]? in
            guard let budget = expenseViewModel.getBudget(for: category.id, month: currentDate) else { return nil }
            return [
                "category": category.name,
                "budget": budget.amount,
                "spent": currentMonthExpenses.first { ($0["category"] as? String) == category.name }?["amount"] as? Double ?? 0
            ]
        }
        
        // 6. Resumen Financiero
        let totalMonthlyExpenses = expenseViewModel.totalMonthlyExpenses
        let savingsRate = monthlyIncome > 0 ? (monthlyIncome - totalMonthlyExpenses) / monthlyIncome : 0
        let committedSpendingPower = recurringExpenses.reduce(0) { $0 + (($1["amount"] as? Double) ?? 0) }
        
        // 7. Datos de Deudas
        let activeDebts = debtViewModel.debts.filter { $0.status == .pending }
        let debtsSummary = activeDebts.map { debt -> [String: Any] in
            [
                "name": debt.name,
                "total_amount": debt.totalAmount,
                "remaining_amount": debt.remainingAmount,
                "progress": debt.progress,
                "next_payment_date": debt.nextPaymentDate as Any,
                "installments": debt.installments.map { installment -> [String: Any] in
                    [
                        "number": installment.number,
                        "amount": installment.amount,
                        "due_date": installment.dueDate,
                        "is_paid": installment.isPaid,
                        "remaining": installment.remainingAmount
                    ]
                },
                "pending_installments": debt.installments.filter { !$0.isPaid }.count,
                "shared_with_partner": debt.sharedWithPartner
            ]
        }
        
        let upcomingPayments = activeDebts.flatMap { debt in
            debt.installments
                .filter { !$0.isPaid && $0.dueDate > currentDate }
                .prefix(5)  // Próximos 5 pagos
                .map { installment -> [String: Any] in
                    [
                        "debt_name": debt.name,
                        "amount": installment.amount,
                        "due_date": installment.dueDate,
                        "installment_number": installment.number
                    ]
                }
        }.sorted { 
            ($0["due_date"] as? Date ?? Date()) < ($1["due_date"] as? Date ?? Date())
        }
        
        let totalDebtAmount = debtViewModel.totalDebtAmount
        let monthlyDebtPayments = upcomingPayments
            .filter { payment in
                guard let dueDate = payment["due_date"] as? Date else { return false }
                return calendar.isDate(dueDate, equalTo: currentDate, toGranularity: .month)
            }
            .reduce(0) { $0 + ((($1["amount"] as? Double) ?? 0)) }
        
        return [
            "current_date": currentDate,
            "accounts_summary": [
                "total_balance": totalBalance,
                "accounts": accounts,
                "primary_account": accounts.first { ($0["is_primary"] as? Bool) == true },
                "accounts_count": accounts.count
            ],
            "financial_summary": [
                "monthly_income": monthlyIncome,
                "monthly_expenses": totalMonthlyExpenses,
                "monthly_debt_payments": monthlyDebtPayments,
                "savings_rate": savingsRate,
                "available_balance": monthlyIncome - totalMonthlyExpenses - monthlyDebtPayments,
                "current_total_balance": totalBalance,
                "total_debt": totalDebtAmount,
                "debt_to_income_ratio": monthlyIncome > 0 ? (monthlyDebtPayments / monthlyIncome) : 0,
                "liquid_assets": accounts.filter { ($0["type"] as? String) == "cash" }
                    .reduce(0) { $0 + (($1["balance"] as? Double) ?? 0) }
            ],
            "expenses": [
                "current_month": currentMonthExpenses,
                "last_month": lastMonthExpenses,
                "recurring": recurringExpenses
            ],
            "budgets": budgets,
            "trends": [
                "monthly_totals": monthlyTotals,
                "top_categories": currentMonthExpenses.prefix(3)
            ],
            "payment_methods": paymentMethods,
            "debts": [
                "total_amount": totalDebtAmount,
                "active_debts_count": debtViewModel.activeDebtsCount,
                "upcoming_payments_count": debtViewModel.upcomingPaymentsCount,
                "active_debts": debtsSummary,
                "upcoming_payments": upcomingPayments,
                "monthly_debt_burden": monthlyDebtPayments,
                "shared_debts": debtsSummary.filter { ($0["shared_with_partner"] as? Bool) == true }
            ],
            "insights": [
                "over_budget_categories": budgets.filter { 
                    let spent = $0["spent"] as? Double ?? 0
                    let budget = $0["budget"] as? Double ?? 0
                    return spent > budget 
                },
                "savings_potential": monthlyIncome - totalMonthlyExpenses,
                "biggest_expense_category": currentMonthExpenses.first?["category"] ?? "None",
                "low_balance_accounts": accounts.filter { ($0["balance"] as? Double ?? 0) < 100 }
                    .map { $0["name"] as? String ?? "" },
                "spending_power": [
                    "total": totalBalance,
                    "available": totalBalance - totalMonthlyExpenses,
                    "committed": committedSpendingPower
                ],
                "debt_insights": [
                    "high_debt_burden": (monthlyDebtPayments / monthlyIncome) > 0.4,
                    "upcoming_payments_this_week": upcomingPayments.filter { payment in
                        guard let dueDate = payment["due_date"] as? Date else { return false }
                        return calendar.isDate(dueDate, equalTo: currentDate, toGranularity: .weekOfYear)
                    },
                    "debt_coverage_ratio": totalBalance / (totalDebtAmount > 0 ? totalDebtAmount : 1)
                ]
            ],
            "recommendations": [
                "should_save": (savingsRate < 0.2),
                "accounts_diversification": accounts.count < 2,
                "low_balance_warning": totalBalance < totalMonthlyExpenses * 2,
                "debt_recommendations": [
                    "should_consolidate": activeDebts.count > 3,
                    "high_interest_warning": monthlyDebtPayments > (monthlyIncome * 0.3),
                    "debt_emergency_fund": totalBalance < (monthlyDebtPayments * 3)
                ]
            ]
        ]
    }
    
    // Agregar un método específico para reportes
    func requestFinancialReport() {
        let reportRequest = """
        Genera un reporte financiero completo de mi situación actual. Mi nombre es Luis Soto. 
        Incluye:
        1. Resumen ejecutivo
        2. Análisis de ingresos y gastos
        3. Estado de deudas
        4. Salud financiera
        5. Riesgos y oportunidades
        6. Recomendaciones específicas
        """
        
        inputMessage = reportRequest
        sendMessage()
    }
} 
