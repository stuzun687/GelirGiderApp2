import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedDate = Date()
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var component: Calendar.Component {
            switch self {
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }
    }
    
    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .weekOfYear]
        let currentComponents = calendar.dateComponents(components, from: selectedDate)
        
        return transactions.filter { transaction in
            let transactionComponents = calendar.dateComponents(components, from: transaction.date)
            
            switch selectedPeriod {
            case .week:
                return transactionComponents.weekOfYear == currentComponents.weekOfYear &&
                       transactionComponents.year == currentComponents.year
            case .month:
                return transactionComponents.month == currentComponents.month &&
                       transactionComponents.year == currentComponents.year
            case .year:
                return transactionComponents.year == currentComponents.year
            }
        }
    }
    
    var periodSummary: (income: Double, expense: Double, balance: Double) {
        // Calculate total balance up to the start of the selected period
        let calendar = Calendar.current
        let periodStart: Date
        
        switch selectedPeriod {
        case .week:
            periodStart = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        case .month:
            periodStart = calendar.startOfMonth(for: selectedDate)
        case .year:
            periodStart = calendar.startOfYear(for: selectedDate)
        }
        
        // Calculate initial balance (all transactions before period start)
        let initialBalance = transactions
            .filter { $0.date < periodStart }
            .reduce(0.0) { result, transaction in
                result + (transaction.type == .income ? transaction.amount : -transaction.amount)
            }
        
        // Calculate period transactions
        var income: Double = 0
        var expense: Double = 0
        
        for transaction in filteredTransactions {
            if transaction.type == .income {
                income += transaction.amount
            } else {
                expense += transaction.amount
            }
        }
        
        // Return cumulative balance
        return (income, expense, initialBalance + income - expense)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Period Selector Card
                        VStack(spacing: 16) {
                            // Balance Section
                            VStack(spacing: 8) {
                                Text("Total Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(formatAmount(periodSummary.balance))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(periodSummary.balance >= 0 ? .green : .red)
                            }
                            
                            // Period Selector
                            VStack(spacing: 12) {
                                // Period Pills
                                HStack(spacing: 12) {
                                    ForEach(TimePeriod.allCases, id: \.self) { period in
                                        Button(action: { withAnimation { selectedPeriod = period } }) {
                                            Text(period.rawValue)
                                                .font(.system(.subheadline, design: .rounded))
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedPeriod == period ? .white : periodColor(for: period))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedPeriod == period ? periodColor(for: period) : periodColor(for: period).opacity(0.1))
                                                )
                                        }
                                    }
                                }
                                
                                // Date Navigation
                                HStack {
                                    Button(action: { moveDate(by: -1) }) {
                                        Image(systemName: "chevron.left.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                    
                                    Text(periodDateString)
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: { moveDate(by: 1) }) {
                                        Image(systemName: "chevron.right.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(TransactionCard(colorScheme: colorScheme))
                        .padding(.horizontal)
                        
                        // Summary Cards
                        HStack(spacing: 16) {
                            SummaryCard(
                                title: "Income",
                                amount: periodSummary.income,
                                color: .green,
                                icon: "arrow.down.circle.fill"
                            )
                            
                            SummaryCard(
                                title: "Expense",
                                amount: periodSummary.expense,
                                color: .red,
                                icon: "arrow.up.circle.fill"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Chart Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Transaction History")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.semibold)
                            
                            Chart {
                                ForEach(groupedTransactions, id: \.date) { group in
                                    BarMark(
                                        x: .value("Date", group.dateString),
                                        y: .value("Amount", group.income),
                                        width: .fixed(20)
                                    )
                                    .foregroundStyle(.green.opacity(0.7))
                                    
                                    BarMark(
                                        x: .value("Date", group.dateString),
                                        y: .value("Amount", -group.expense),
                                        width: .fixed(20)
                                    )
                                    .foregroundStyle(.red.opacity(0.7))
                                }
                            }
                            .frame(height: 200)
                        }
                        .padding(24)
                        .background(TransactionCard(colorScheme: colorScheme))
                        .padding(.horizontal)
                        
                        // Recent Transactions
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Transactions")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                NavigationLink(destination: TransactionsView()) {
                                    Text("See All")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            
                            ForEach(Array(filteredTransactions.prefix(5))) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Dashboard")
        }
    }
    
    private var periodDateString: String {
        let formatter = DateFormatter()
        
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "'Week' w, yyyy"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: selectedDate)
    }
    
    private func moveDate(by value: Int) {
        if let newDate = Calendar.current.date(
            byAdding: selectedPeriod.component,
            value: value,
            to: selectedDate
        ) {
            withAnimation {
                selectedDate = newDate
            }
        }
    }
    
    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        return formatter.string(from: NSNumber(value: value)) ?? "₺0"
    }
    
    private var groupedTransactions: [(date: Date, dateString: String, income: Double, expense: Double)] {
        let calendar = Calendar.current
        var groups: [Date: (income: Double, expense: Double)] = [:]
        
        // Create date formatter for x-axis labels
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d"
        case .year:
            formatter.dateFormat = "MMM"
        }
        
        // Group transactions by date
        for transaction in filteredTransactions {
            let date: Date
            switch selectedPeriod {
            case .week:
                date = calendar.startOfDay(for: transaction.date)
            case .month:
                date = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: transaction.date)) ?? transaction.date
            case .year:
                date = calendar.date(from: calendar.dateComponents([.year, .month], from: transaction.date)) ?? transaction.date
            }
            
            let current = groups[date] ?? (income: 0, expense: 0)
            if transaction.type == .income {
                groups[date] = (income: current.income + transaction.amount, expense: current.expense)
            } else {
                groups[date] = (income: current.income, expense: current.expense + transaction.amount)
            }
        }
        
        return groups.map { date, values in
            (
                date: date,
                dateString: formatter.string(from: date),
                income: values.income,
                expense: values.expense
            )
        }
        .sorted { $0.date < $1.date }
    }
    
    private func periodColor(for period: TimePeriod) -> Color {
        switch period {
        case .week: return .blue
        case .month: return .purple
        case .year: return .indigo
        }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            
            Text(formatAmount(amount))
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(color.opacity(0.1))
        )
    }
    
    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        return formatter.string(from: NSNumber(value: value)) ?? "₺0"
    }
}

struct TransactionCard: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(.systemGray6).opacity(0.1))
            .shadow(color: .black.opacity(0.2), radius: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .clear,
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    func startOfYear(for date: Date) -> Date {
        let components = dateComponents([.year], from: date)
        return self.date(from: components) ?? date
    }
} 
