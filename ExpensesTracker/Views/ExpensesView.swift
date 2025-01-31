import SwiftUI

enum ExpenseOption {
    case general
    case recurring
}

struct ExpensesView: View {
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @State private var showingAddExpense = false
    @State private var isMonthMode = true // Alternar entre modo Mes y Día
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedDate = Date() // Para el modo día
    @State private var selectedCategoryId: UUID?
    @State private var showingActionSheet = false
    @State private var selectedOption: ExpenseOption = .general

    private var filteredExpenses: [Expense] {
        if isMonthMode {
            let date = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth))!
            return expenseViewModel.getFilteredExpenses(
                month: date,
                categoryId: selectedCategoryId,
                isRecurring: selectedOption == .recurring  // Pasamos isRecurring según la opción seleccionada
            )
        } else {
            return expenseViewModel.getFilteredExpenses(
                month: selectedDate,
                categoryId: selectedCategoryId,
                isRecurring: selectedOption == .recurring  // Igual aquí
            )
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Picker("Modo de Fecha", selection: $isMonthMode) {
                        Text("Por Mes").tag(true)
                        Text("Por Día").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if isMonthMode {
                        MonthYearPickerView(
                            minimumDate: Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
                            maximumDate: Calendar.current.date(byAdding: .year, value: 10, to: Date())!,
                            selectedMonth: $selectedMonth,
                            selectedYear: $selectedYear
                        )
                        .frame(height: 100)
                    } else {
                        DatePicker(
                            "Seleccionar Día",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryFilterChip(
                                name: "Todos",
                                isSelected: selectedCategoryId == nil
                            ) {
                                selectedCategoryId = nil
                            }

                            ForEach(expenseViewModel.categories) { category in
                                CategoryFilterChip(
                                    name: category.name,
                                    isSelected: category.id == selectedCategoryId
                                ) {
                                    selectedCategoryId = category.id
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))

                List {
                    ForEach(filteredExpenses) { expense in
                        ExpenseRowView(expense: expense)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteExpense)
                }
                .refreshable {
                    expenseViewModel.reloadExpenses()
                }
                .listStyle(.plain)
            }
            .navigationTitle(selectedOption == .general ? "Gastos Generales" : "Gastos Recurrentes")
            .navigationBarItems(
                leading: Button(action: {
                    showingActionSheet = true
                }) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(22)
                        .padding(5)
                }
                .actionSheet(isPresented: $showingActionSheet) {
                    ActionSheet(
                        title: Text("Selecciona una opción"),
                        buttons: [
                            .default(Text("Gastos Generales")) {
                                selectedOption = .general
                            },
                            .default(Text("Gastos Recurrentes")) {
                                selectedOption = .recurring
                            },
                            .cancel()
                        ]
                    )
                },
                trailing: Button(action: {
                    showingAddExpense = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            )
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(isRecurring: selectedOption == .recurring)
        }
    }
    
    // Helper to get the first day of a given month
    private func firstDayOfMonth(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    // Delete Handler
    private func deleteExpense(at offsets: IndexSet) {
        offsets.forEach { index in
            let expense = filteredExpenses[index]
            expenseViewModel.deleteExpense(expense)
        }
    }
}

struct CategoryFilterChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct MonthYearPickerView: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    private var minimumDate: Date
    private var maximumDate: Date
    private var months: [String]
    private var years: [Int] = []
    
    private var availableYears: [Int] {
        let minYear = Calendar.current.component(.year, from: minimumDate)
        let maxYear = Calendar.current.component(.year, from: maximumDate)
        return Array(minYear...maxYear)
    }
    
    init(minimumDate: Date, maximumDate: Date, selectedMonth: Binding<Int>, selectedYear: Binding<Int>) {
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self._selectedMonth = selectedMonth
        self._selectedYear = selectedYear
        self.months = Calendar.current.monthSymbols.map { $0.capitalized }
        self.years = availableYears
    }
    
    var body: some View {
        HStack {
            Picker("Month", selection: $selectedMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text(self.months[month - 1]).tag(month)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            Picker("Year", selection: $selectedYear) {
                ForEach(availableYears, id: \.self) { year in
                    Text(verbatim: "\(year)").tag(year)
                }
            }
            .pickerStyle(WheelPickerStyle())
        }
        .onChange(of: selectedMonth) {
            guard let date = DateComponents(calendar: Calendar.current, year: selectedYear, month: selectedMonth, day: 1, hour: 0, minute: 0, second: 0).date else { return }
            if date < minimumDate {
                selectedYear = Calendar.current.component(.year, from: minimumDate)
                selectedMonth = Calendar.current.component(.month, from: minimumDate)
            } else if date > maximumDate {
                selectedYear = Calendar.current.component(.year, from: maximumDate)
                selectedMonth = Calendar.current.component(.month, from: maximumDate)
            }
        }
    }
}
