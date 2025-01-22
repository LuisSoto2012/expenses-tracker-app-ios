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
            .navigationTitle("Gestión de Deudas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddDebt = true }) {
                        Image(systemName: "plus.circle.fill")
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
                    Text("Deuda Total")
                        .font(.subheadline)
                    Spacer()
                    Text(viewModel.totalDebtAmount.formatted(.currency(code: "PEN")))
                        .font(.headline)
                }
                
                HStack {
                    Text("Deudas Activas")
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.activeDebtsCount)")
                        .font(.headline)
                }
                
                HStack {
                    Text("Pagos Pendientes")
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
                Text("Tus Deudas")
                Spacer()
                Picker("Filtrar", selection: $selectedFilter) {
                    Text("Todas").tag(Optional<DebtStatus>.none)
                    Text("Pendientes").tag(Optional<DebtStatus>.some(.pending))
                    Text("Pagadas").tag(Optional<DebtStatus>.some(.paid))
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
            
            Text(debt.totalAmount.formatted(.currency(code: "PEN")))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: debt.progress)
                .tint(debt.progress == 1 ? .green : .blue)
            
            Text("\(Int(debt.progress * 100))% - \(debt.installments.filter(\.isPaid).count)/\(debt.numberOfInstallments) pagados")
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
