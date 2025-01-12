import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var transactions: [Transaction]
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
    
    var periodSummary: (income: Double, expense: Double) {
        var income: Double = 0
        var expense: Double = 0
        
        for transaction in filteredTransactions {
            if transaction.type == .income {
                income += transaction.amount
            } else {
                expense += transaction.amount
            }
        }
        
        return (income, expense)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    VStack(spacing: 12) {
                        HStack {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Button(action: { selectedPeriod = period }) {
                                    Text(period.rawValue)
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedPeriod == period ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedPeriod == period ? Color.accentColor : Color(.systemGray6))
                                        )
                                }
                            }
                        }
                        
                        // Date Navigation
                        HStack {
                            Button(action: { moveDate(by: -1) }) {
                                Image(systemName: "chevron.left")
                            }
                            
                            Spacer()
                            
                            Text(periodDateString)
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: { moveDate(by: 1) }) {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
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
                    
                    // Charts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Transaction History")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
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
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Transactions")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ForEach(Array(filteredTransactions.prefix(5))) { transaction in
                            ModernTransactionRow(transaction: transaction)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
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
            selectedDate = newDate
        }
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
        
        // Sort and format the groups
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
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