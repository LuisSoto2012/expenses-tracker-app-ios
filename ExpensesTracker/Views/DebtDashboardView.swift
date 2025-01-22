import SwiftUI

struct DebtDashboardView: View {
    @StateObject private var viewModel = DebtViewModel()
    @State private var showingAddDebt = false
    @State private var selectedFilter: DebtStatus?
    
    var body: some View {
        NavigationView {
            List {
                debtsSummarySection
                
                debtsSection
            }
            .navigationTitle("Debt Management")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddDebt = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDebt) {
                AddDebtView(viewModel: viewModel)
            }
        }
    }
    
    private var debtsSummarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Total Debt")
                        .font(.subheadline)
                    Spacer()
                    Text(viewModel.totalDebtAmount.formatted(.currency(code: "USD")))
                        .font(.headline)
                }
                
                HStack {
                    Text("Active Debts")
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.activeDebtsCount)")
                        .font(.headline)
                }
                
                HStack {
                    Text("Upcoming Payments")
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.upcomingPaymentsCount)")
                        .font(.headline)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var debtsSection: some View {
        Section {
            ForEach(viewModel.filteredDebts) { debt in
                NavigationLink(destination: DebtDetailView(debt: debt, viewModel: viewModel)) {
                    DebtRowView(debt: debt)
                }
            }
        } header: {
            HStack {
                Text("Your Debts")
                Spacer()
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(Optional<DebtStatus>.none)
                    Text("Pending").tag(Optional<DebtStatus>.some(.pending))
                    Text("Paid").tag(Optional<DebtStatus>.some(.paid))
                }
                .pickerStyle(.menu)
            }
        }
    }
}

struct DebtRowView: View {
    let debt: Debt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(debt.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: debt.status)
            }
            
            Text(debt.totalAmount.formatted(.currency(code: "USD")))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: debt.progress)
                .tint(debt.progress == 1 ? .green : .blue)
            
            Text("\(Int(debt.progress * 100))% - \(debt.installments.filter(\.isPaid).count)/\(debt.numberOfInstallments) paid")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: DebtStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status == .paid ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
            .foregroundColor(status == .paid ? .green : .orange)
            .clipShape(Capsule())
    }
} 
