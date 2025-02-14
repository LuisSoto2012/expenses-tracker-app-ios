import Foundation

class ViewModelFactory {
    static let shared = ViewModelFactory()
    
    private init() {}
    
    lazy var accountViewModel: AccountViewModel = {
        return AccountViewModel()
    }()
    
    lazy var expenseViewModel: ExpenseViewModel = {
        return ExpenseViewModel(accountViewModel: accountViewModel)
    }()
    
    lazy var incomeViewModel: IncomeViewModel = {
        return IncomeViewModel()
    }()
    
    lazy var debtViewModel: DebtViewModel = {
        return DebtViewModel()
    }()
}
