import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @State private var showingCategorySheet = false
    @State private var showingExportSheet = false
    @State private var showingSignOutAlert = false
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showingLanguageAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Categories Section
                Section(String(localized: "categories")) {
                    Button(action: { showingCategorySheet = true }) {
                        HStack {
                            Label(String(localized: "manage_categories"), systemImage: "tag")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Budget Section
                Section(String(localized: "budget")) {
                    NavigationLink(destination: BudgetSettingsView().environmentObject(expenseViewModel)) {
                        Label(String(localized: "budget_settings"), systemImage: "chart.bar")
                    }
                }
                
                // Data Management
                Section(String(localized: "data")) {
                    Button(action: { showingExportSheet = true }) {
                        Label(String(localized: "export_data"), systemImage: "square.and.arrow.up")
                    }
                }
                
                // Account Section
                Section(String(localized: "account")) {
                    if let user = Auth.auth().currentUser {
                        HStack {
                            Label(String(localized: "email"), systemImage: "envelope")
                            Spacer()
                            Text(user.email ?? "")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(role: .destructive, action: { showingSignOutAlert = true }) {
                            Label(String(localized: "sign_out"), systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
                
                // Language Section
                Section(String(localized: "language")) {
                    Picker(String(localized: "language"), selection: $languageManager.currentLanguage) {
                        ForEach(LanguageManager.Language.allCases, id: \.self) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    }
                }
                
                // About Section
                Section(String(localized: "about")) {
                    HStack {
                        Label(String(localized: "version"), systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "settings"))
            .id(languageManager.refreshID)
        }
        .sheet(isPresented: $showingCategorySheet) {
            CategoryManagementView()
                .environmentObject(expenseViewModel)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                try? Auth.auth().signOut()
            }
        } message: {
            Text(String(localized: "sign_out_confirm_message"))
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
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
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
                TextField("Category Name", text: $name)
                
                ColorPicker("Color", selection: Binding(
                    get: { Color(hex: color) ?? .blue },
                    set: { color = $0.toHex() ?? "#0000FF" }
                ))
                
                // Icon picker would go here
                TextField("Icon Name (SF Symbol)", text: $icon)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                        dismiss()
                    }
                    .disabled(name.isEmpty || color.isEmpty || icon.isEmpty)
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .add:
            return "New Category"
        case .edit:
            return "Edit Category"
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
