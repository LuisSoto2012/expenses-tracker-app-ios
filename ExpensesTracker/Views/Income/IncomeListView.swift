import SwiftUI

struct IncomeListView: View {
    @ObservedObject var viewModel: IncomeViewModel
    
    var body: some View {
        List {
            Section(header: Text("Monthly Income: \(viewModel.calculateMonthlyIncome(), specifier: "%.2f")")) {
                ForEach(viewModel.incomes) { income in
                    IncomeRowView(income: income)
                }
                .onDelete(perform: viewModel.deleteIncome)
            }
        }
        .navigationTitle("Income Sources")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showingAddIncome = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddIncome) {
            AddIncomeView(viewModel: viewModel)
        }
    }
}

struct IncomeRowView: View {
    let income: Income
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(income.name)
                .font(.headline)
            HStack {
                Text(income.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if let amount = income.amount {
                    Text("\(amount, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            Text(income.frequency.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 