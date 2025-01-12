import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Query private var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var searchText = ""
    @State private var filterType: TransactionType?
    @State private var filterRecurring: RecurringFilter = .all
    @State private var showingSortOptions = false
    @State private var sortOrder: SortOrder = .dateDescending
    
    enum SortOrder {
        case dateDescending
        case dateAscending
        case amountDescending
        case amountAscending
    }
    
    enum RecurringFilter {
        case all
        case oneTime
        case recurring
        
        var title: String {
            switch self {
            case .all: return "All"
            case .oneTime: return "One-time"
            case .recurring: return "Recurring"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .oneTime: return "1.circle"
            case .recurring: return "repeat.circle"
            }
        }
    }
    
    var filteredTransactions: [Transaction] {
        let filtered = transactions.filter { transaction in
            let matchesSearch = searchText.isEmpty || 
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText)
            
            let matchesType = filterType == nil || transaction.type == filterType
            
            let matchesRecurring = filterRecurring == .all ||
                (filterRecurring == .recurring && transaction.isRecurring) ||
                (filterRecurring == .oneTime && !transaction.isRecurring)
            
            return matchesSearch && matchesType && matchesRecurring
        }
        
        return filtered.sorted { first, second in
            switch sortOrder {
            case .dateDescending: return first.date > second.date
            case .dateAscending: return first.date < second.date
            case .amountDescending: return first.amount > second.amount
            case .amountAscending: return first.amount < second.amount
            }
        }
    }
    
    var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(colorScheme == .dark ? .systemGray6 : .systemBackground),
                        Color(colorScheme == .dark ? .systemGray5 : .systemGray6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Section
                    VStack(spacing: 12) {
                        // Transaction Type Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterPill(
                                    title: "All",
                                    icon: "tray.fill",
                                    isSelected: filterType == nil
                                ) {
                                    withAnimation { filterType = nil }
                                }
                                
                                FilterPill(
                                    title: "Income",
                                    icon: "arrow.down.circle.fill",
                                    color: .green,
                                    isSelected: filterType == .income
                                ) {
                                    withAnimation { filterType = .income }
                                }
                                
                                FilterPill(
                                    title: "Expense",
                                    icon: "arrow.up.circle.fill",
                                    color: .red,
                                    isSelected: filterType == .expense
                                ) {
                                    withAnimation { filterType = .expense }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Recurring Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach([RecurringFilter.all, .oneTime, .recurring], id: \.self) { filter in
                                    FilterPill(
                                        title: filter.title,
                                        icon: filter.icon,
                                        isSelected: filterRecurring == filter
                                    ) {
                                        withAnimation { filterRecurring = filter }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(
                        TransactionCard(colorScheme: colorScheme)
                            .shadow(color: .black.opacity(0.05), radius: 5)
                    )
                    
                    // Transactions List
                    ScrollView {
                        LazyVStack(spacing: 24, pinnedViews: .sectionHeaders) {
                            ForEach(groupedTransactions, id: \.0) { month, transactions in
                                Section {
                                    VStack(spacing: 16) {
                                        ForEach(transactions) { transaction in
                                            TransactionRow(transaction: transaction)
                                                .contextMenu {
                                                    Button(role: .destructive) {
                                                        deleteTransaction(transaction)
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                } header: {
                                    HStack {
                                        Text(month)
                                            .font(.system(.headline, design: .rounded))
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        TransactionCard(colorScheme: colorScheme)
                                            .shadow(color: .black.opacity(0.05), radius: 5)
                                    )
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            sortOrder = .dateDescending
                        } label: {
                            Label("Date (Newest First)", systemImage: sortOrder == .dateDescending ? "checkmark" : "")
                        }
                        
                        Button {
                            sortOrder = .dateAscending
                        } label: {
                            Label("Date (Oldest First)", systemImage: sortOrder == .dateAscending ? "checkmark" : "")
                        }
                        
                        Button {
                            sortOrder = .amountDescending
                        } label: {
                            Label("Amount (Highest First)", systemImage: sortOrder == .amountDescending ? "checkmark" : "")
                        }
                        
                        Button {
                            sortOrder = .amountAscending
                        } label: {
                            Label("Amount (Lowest First)", systemImage: sortOrder == .amountAscending ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)
    }
}

struct FilterPill: View {
    let title: String
    let icon: String
    var color: Color = .accentColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.systemGray6))
            )
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(transaction.type == .expense ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: getCategoryIcon(transaction.category))
                    .font(.title2)
                    .foregroundColor(transaction.type == .expense ? .red : .green)
            }
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                    
                    if transaction.isRecurring {
                        RecurringBadge(type: transaction.recurringType)
                    }
                }
                
                HStack {
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if transaction.isRecurring {
                        Text("•")
                            .foregroundColor(.gray)
                        Text(transaction.recurringType.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(transaction.amount))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type == .expense ? .red : .green)
                
                Text(formatDate(transaction.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            TransactionCard(colorScheme: colorScheme)
        )
    }
    
    private func getCategoryIcon(_ category: String) -> String {
        let icons = [
            "Food": "fork.knife",
            "Transportation": "car.fill",
            "Shopping": "cart.fill",
            "Bills": "doc.text.fill",
            "Entertainment": "tv.fill",
            "Salary": "dollarsign.circle.fill",
            "Investment": "chart.line.uptrend.xyaxis",
            "Other": "creditcard.fill"
        ]
        return icons[category] ?? "creditcard.fill"
    }
    
    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        return formatter.string(from: NSNumber(value: value)) ?? "₺0"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct RecurringBadge: View {
    let type: RecurringType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "repeat")
            Text(type.description)
        }
        .font(.caption2)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.8))
        )
    }
} 
