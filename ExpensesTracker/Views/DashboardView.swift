import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @State private var selectedDate = Date()
    
    private var monthlyExpensesByCategory: [(Category, Double)] {
        expenseViewModel.getMonthlyExpensesByCategory(for: selectedDate)
    }
    
    private var monthlyTotals: [(Date, Double)] {
        expenseViewModel.getMonthlyTotalExpenses(for: 6)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Picker
                    DatePicker(
                        "Select Month",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    
                    // Category Breakdown Chart
                    ChartSection(
                        title: "Category Breakdown",
                        content: CategoryPieChart(data: monthlyExpensesByCategory)
                    )
                    
                    // Category List
                    ChartSection(
                        title: "Expenses by Category",
                        content: CategoryBreakdownList(data: monthlyExpensesByCategory)
                    )
                    
                    // Monthly Trend Chart
                    ChartSection(
                        title: "6-Month Trend",
                        content: MonthlyTrendChart(data: monthlyTotals)
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct ChartSection<Content: View>: View {
    let title: String
    let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            content
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
        }
    }
}

struct CategoryPieChart: View {
    let data: [(Category, Double)]
    
    var body: some View {
        Chart(data, id: \.0.id) { item in
            SectorMark(
                angle: .value("Amount", item.1),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
            )
            .foregroundStyle(item.0.uiColor)
        }
        .frame(height: 200)
        
        // Legend
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(data, id: \.0.id) { item in
                HStack {
                    Circle()
                        .fill(item.0.uiColor)
                        .frame(width: 8, height: 8)
                    Text(item.0.name)
                        .font(.caption)
                    Spacer()
                    Text("$\(item.1, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct CategoryBreakdownList: View {
    let data: [(Category, Double)]
    private var total: Double { data.reduce(0) { $0 + $1.1 } }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(data, id: \.0.id) { item in
                HStack {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.0.uiColor)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: item.0.icon)
                                    .foregroundColor(.white)
                            }
                        
                        VStack(alignment: .leading) {
                            Text(item.0.name)
                                .font(.subheadline)
                            Text("\(item.1 / total * 100, specifier: "%.1f")%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("$\(item.1, specifier: "%.2f")")
                        .font(.subheadline)
                }
            }
        }
    }
}

struct MonthlyTrendChart: View {
    let data: [(Date, Double)]
    
    var body: some View {
        Chart(data, id: \.0) { item in
            LineMark(
                x: .value("Month", item.0, unit: .month),
                y: .value("Amount", item.1)
            )
            .foregroundStyle(Color.accentColor)
            
            PointMark(
                x: .value("Month", item.0, unit: .month),
                y: .value("Amount", item.1)
            )
            .foregroundStyle(Color.accentColor)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel("$\(value.as(Double.self) ?? 0, specifier: "%.0f")")
            }
        }
        .frame(height: 200)
    }
} 
