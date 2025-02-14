import SwiftUI
import FirebaseAuth
import SFSymbolsPicker

struct SettingsView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @StateObject private var incomeViewModel = IncomeViewModel()
    @State private var showingCategorySheet = false
    @State private var showingExportSheet = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSelectiveDeleteConfirmation = false
    @State private var selectedDataToDelete: String? = nil
    @State private var showingSuccessMessage = false
    @State private var successMessage = ""
    
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var openAIService = OpenAIService()
    @State private var isLoadingBalance = false
    @State private var balanceError: String?
    
    // Mapeo de nombres en español a inglés
    let spanishToEnglishMap: [String: String] = [
        "Cuentas": "accounts",
        "Presupuestos": "budgets",
        "Categorias": "categories",
        "Deudas": "debts",
        "Gastos": "expenses",
        "Ingresos": "incomes",
        "Métodos de Pago": "paymentMethods"
    ]
    
    var body: some View {
        NavigationView {
            List {
                // Accounts Section
               Section("Cuentas") {
                   NavigationLink(destination: AccountManagementView()) {
                       Label("Gestionar Cuentas", systemImage: "banknote")
                   }
               }
               
               // Incomes section
               Section("Income & Payments") {
                   NavigationLink(destination: IncomeListView(viewModel: incomeViewModel)) {
                       Label("Fuente de Ingresos", systemImage: "dollarsign.circle")
                   }
                   
                   NavigationLink(destination: PaymentMethodsView(viewModel: incomeViewModel)) {
                       Label("Metodos de Pago", systemImage: "creditcard")
                   }
               }
               
               // Categories Section
               Section("Categorías") {
                   Button(action: { showingCategorySheet = true }) {
                       HStack {
                           Label {
                               Text("Administrar Categorías")
                                   .foregroundColor(.primary)
                           } icon: {
                               Image(systemName: "tag")
                           }
                           Spacer()
                           Image(systemName: "chevron.right")
                               .foregroundColor(.secondary)
                       }
                   }
               }
               
               // Budget Section
               Section("Presupuesto") {
                   NavigationLink(destination: BudgetSettingsView().environmentObject(expenseViewModel)) {
                       Label("Configuración de Presupuesto", systemImage: "chart.bar")
                   }
               }
               
               // Data Management
               Section("Datos") {
                   Button(action: { showingExportSheet = true }) {
                       Label {
                           Text("Exportar Datos")
                               .foregroundColor(.primary)
                       } icon: {
                           Image(systemName: "square.and.arrow.up")
                       }
                   }
               }
               
               // OpenAI API
               Section("OpenAI API") {
                   VStack(alignment: .leading, spacing: 12) {
                       Text("Uso de Tokens")
                           .font(.headline)
                       
                       VStack(alignment: .leading, spacing: 8) {
                           // Tokens Disponibles
                           VStack(alignment: .leading, spacing: 4) {
                               HStack {
                                   Text("Tokens Disponibles:")
                                   Spacer()
                                   Text("\(2_000_000 - openAIService.totalTokensUsed)")
                                       .bold()
                               }
                               ProgressView(value: Double(openAIService.totalTokensUsed), total: 2_000_000)
                                   .tint(.green)
                           }
                           
                           // Tokens Usados
                           VStack(alignment: .leading, spacing: 4) {
                               HStack {
                                   Text("Tokens Usados:")
                                   Spacer()
                                   Text("\(openAIService.totalTokensUsed)")
                                       .bold()
                               }
                               ProgressView(value: Double(openAIService.totalTokensUsed), total: 2_000_000)
                                   .tint(.orange)
                           }
                           
                           // Total de Tokens
                           HStack {
                               Text("Total de Tokens:")
                               Spacer()
                               Text("2,000,000")
                                   .bold()
                           }
                       }
                       .padding(.vertical, 4)
                   }
                   .padding(.vertical, 4)
               }
               
               // Account Section
               Section("Cuenta") {
                   if let user = Auth.auth().currentUser {
                       HStack {
                           Label("Correo Electrónico", systemImage: "envelope")
                           Spacer()
                           Text(user.email ?? "")
                               .foregroundColor(.secondary)
                       }
                       
                       Button(role: .destructive, action: { showingSignOutAlert = true }) {
                           Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                       }
                   }
               }
               
               // About Section
               Section("Acerca de") {
                   HStack {
                       Label("Versión", systemImage: "info.circle")
                       Spacer()
                       Text("1.0.0")
                           .foregroundColor(.secondary)
                   }
               }
                
                // Data Management
                Section("Datos") {
                    Button(action: { showingExportSheet = true }) {
                        Label("Exportar Datos", systemImage: "square.and.arrow.up")
                    }
                    
                    // Nueva opción para eliminar datos específicos
                    Button(action: { showingSelectiveDeleteConfirmation = true }) {
                        Label("Eliminar Datos Específicos", systemImage: "trash.circle")
                            .foregroundColor(.red)
                    }
                    
                    // Opción para eliminar todo
                    Button(action: { showingDeleteConfirmation = true }) {
                        Label("Eliminar Todo", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                .alert("Eliminar Datos Específicos", isPresented: $showingSelectiveDeleteConfirmation) {
                    Button("Cancelar", role: .cancel) { }
                    ForEach(["Cuentas", "Presupuestos", "Categorias", "Deudas", "Gastos", "Ingresos", "Métodos de Pago"], id: \.self) { item in
                        Button(item, role: .destructive) {
                            if let englishKey = spanishToEnglishMap[item] {
                                deleteSpecificData(type: englishKey)
                            }
                        }
                    }
                } message: {
                    Text("Selecciona qué datos deseas eliminar.")
                }
                .alert("Eliminar Todo", isPresented: $showingDeleteConfirmation) {
                    Button("Cancelar", role: .cancel) { }
                    Button("Eliminar", role: .destructive) {
                        deleteAllData()
                    }
                } message: {
                    Text("¿Estás seguro de que deseas eliminar todos los datos? Esta acción no se puede deshacer.")
                }
            }
            .navigationTitle("Configuración")
            .alert(isPresented: $showingSuccessMessage) {
                Alert(
                    title: Text("Éxito"),
                    message: Text(successMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showingCategorySheet) {
            CategoryManagementView()
                .environmentObject(expenseViewModel)
        }
        .alert("Cerrar Sesión", isPresented: $showingSignOutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                try? Auth.auth().signOut()
            }
        } message: {
            Text("¿Estás seguro de que deseas cerrar sesión?")
        }
        .onAppear {
            refreshBalance()
        }
    }
    
    private func deleteAllData() {
        // Llamamos a FirebaseService para eliminar las colecciones
        firebaseService.deleteAllCollectionsExceptCategories()
        successMessage = "Todos los datos han sido eliminados exitosamente."
        showingSuccessMessage = true
    }
    
    private func deleteSpecificData(type: String) {
        firebaseService.deleteCollection(collectionName: type)
        
        if type == "accounts" {
            firebaseService.deleteCollection(collectionName: "transactions")
        }
        
        if let spanishName = spanishToEnglishMap.first(where: { $0.value == type })?.key {
            successMessage = "Los datos de \(spanishName) han sido eliminados exitosamente."
            showingSuccessMessage = true
        }
    }
    
    private func refreshBalance() {
        isLoadingBalance = true
        balanceError = nil
        
        Task {
            do {
                _ = try await openAIService.fetchCreditBalance()
            } catch {
                balanceError = "Error al cargar el saldo: \(error.localizedDescription)"
            }
            isLoadingBalance = false
        }
    }
}

struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(expenseViewModel.categories) { category in
                    CategoryRow(category: category) {
                        editingCategory = category
                    }
                }
                .onDelete { indexSet in
                    expenseViewModel.deleteCategories(at: indexSet)
                }
            }
            .navigationTitle("Categorías")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hecho") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddCategory = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryFormView(mode: .add)
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormView(mode: .edit(category))
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack {
                Circle()
                    .fill(category.uiColor)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: category.icon)
                            .foregroundColor(.white)
                    }
                
                Text(category.name)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CategoryFormView: View {
    enum Mode {
        case add
        case edit(Category)
    }
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    
    let mode: Mode
    
    @State private var name: String = ""
    @State private var color: String = ""
    @State private var icon: String = ""
    @State private var isPickerPresented = false
    
    init(mode: Mode) {
        self.mode = mode
        if case .edit(let category) = mode {
            _name = State(initialValue: category.name)
            _color = State(initialValue: category.color)
            _icon = State(initialValue: category.icon)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nombre de Categoría", text: $name)
                
                ColorPicker("Color", selection: Binding(
                    get: { Color(hex: color) ?? .blue },
                    set: { color = $0.toHex() ?? "#0000FF" }
                ))
                
                // Icon picker would go here
                HStack {
                    Text("Icono")
                    Spacer()
                    Image(systemName: icon)
                        .font(.title2)
                }
                .onTapGesture {
                    isPickerPresented.toggle()
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveCategory()
                        dismiss()
                    }
                    .disabled(name.isEmpty || color.isEmpty || icon.isEmpty)
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                SymbolsPicker(selection: $icon, title: "Elige un ícono", autoDismiss: true) {
                    Image(systemName: "xmark.diamond.fill") // Icono de cierre
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .add:
            return "Nueva Categoría"
        case .edit:
            return "Editar Categoría"
        }
    }
    
    private func saveCategory() {
        let category: Category
        switch mode {
        case .add:
            category = Category(id: UUID(), name: name, color: color, icon: icon)
        case .edit(let existingCategory):
            category = Category(id: existingCategory.id, name: name, color: color, icon: icon)
        }
        
        if case .edit = mode {
            expenseViewModel.updateCategory(category)
        } else {
            expenseViewModel.addCategory(category)
        }
    }
}
