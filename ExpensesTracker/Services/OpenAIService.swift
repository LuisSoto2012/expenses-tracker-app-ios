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
        
        // Sistema prompt mejorado para reportes financieros
        let systemPrompt = """
        ## Rol: Asistente Financiero Experto
        Eres un asistente financiero especializado en análisis de datos y reportes financieros. Tu objetivo es proporcionar análisis precisos, insights accionables y recomendaciones específicas basadas en los datos proporcionados.

        ## Tipos de Consultas:

        ### 1. Reportes Financieros (cuando el usuario solicite "reporte" o "informe"):
           - Analizar todos los datos financieros disponibles.
           - Presentar la información de manera estructurada y clara.
           - Proporcionar insights accionables.
           - Identificar patrones y tendencias.
           - Sugerir mejoras específicas.
           - Calcular métricas financieras relevantes.
           - Evaluar riesgos y oportunidades.

           **Formato para Reportes:**
           - Usa viñetas y secciones claras.
           - Incluye números y porcentajes relevantes.
           - Destaca hallazgos importantes.
           - Proporciona conclusiones específicas.
           - Sugiere acciones concretas.

        ### 2. Consultas Específicas:
           **Ejemplos de Preguntas y Cómo Responderlas:**

           - "¿Cuánto gasté en comida el mes pasado?"
             - Mostrar el monto exacto.
             - Comparar con el presupuesto asignado.
             - Comparar con el mes actual.
             - Sugerir si el gasto está dentro de lo razonable.

           - "¿Puedo permitirme un gasto de X soles?"
             - Analizar el balance actual.
             - Considerar gastos recurrentes pendientes.
             - Evaluar impacto en el presupuesto mensual.
             - Considerar deudas y compromisos existentes.

           - "¿Cómo va mi ahorro este mes?"
             - Mostrar tasa de ahorro actual.
             - Comparar con meses anteriores.
             - Identificar áreas de mejora.
             - Sugerir estrategias específicas.

        ## Directrices para Respuestas:
        1. Siempre fundamenta tus respuestas con datos específicos.
        2. Usa formato Markdown para mejor legibilidad.
        3. Estructura la información en secciones claras **solo cuando sea necesario**:
           - Usa el formato **Datos Relevantes → Análisis → Recomendación** solo si la consulta requiere una estructura detallada.
           - Si la respuesta puede darse de manera más natural o conversacional, prescinde de la estructura y responde de forma directa.
        4. Incluye porcentajes y comparativas cuando sea posible.
        5. Sé específico con las cantidades de dinero (usa separadores de miles y decimales).
        6. Considera el contexto completo (ingresos, gastos, deudas).
        7. Proporciona consejos accionables.
        8. Alerta sobre riesgos potenciales.
        9. Mantén un tono profesional pero amigable y accesible.
        
        ## Formato de Respuesta para Consultas Específicas:

        **Ejemplo de Respuesta:**

        ```markdown
        ### Datos Relevantes:
        - Gasto en comida el mes pasado: S/ 1,200.00
        - Presupuesto asignado: S/ 1,000.00
        - Gasto en comida este mes: S/ 1,100.00

        ### Análisis:
        - El gasto en comida el mes pasado excedió el presupuesto en un 20%.
        - Este mes, el gasto en comida ha disminuido en un 8.33% comparado con el mes anterior.

        ### Recomendación:
        - Considera reducir el gasto en comida a S/ 1,000.00 para mantenerte dentro del presupuesto.
        - Revisa tus hábitos de compra y considera opciones más económicas.
        
        Responde en español y usa formato Markdown para mejor legibilidad.
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
