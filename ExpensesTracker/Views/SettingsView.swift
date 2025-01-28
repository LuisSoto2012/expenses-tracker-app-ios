import SwiftUI
import FirebaseAuth
import SFSymbolsPicker

struct SettingsView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @StateObject private var incomeViewModel = IncomeViewModel()
    @State private var showingCategorySheet = false
    @State private var showingExportSheet = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Incomes section
                Section("Income & Payments") {
                    NavigationLink(destination: IncomeListView(viewModel: incomeViewModel)) {
                        Label("Income Sources", systemImage: "dollarsign.circle")
                    }
                    
                    NavigationLink(destination: PaymentMethodsView(viewModel: incomeViewModel)) {
                        Label("Payment Methods", systemImage: "creditcard")
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
            }
            .navigationTitle("Configuración")
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
