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
    @State private var selectedPeriod: TimePeriod = .all
    @State private var selectedDate = Date()
    
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
    
    enum TimePeriod: String, CaseIterable {
        case all = "All Time"
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        
        var component: Calendar.Component {
            switch self {
            case .all: return .era
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
        
        let filtered = transactions.filter { transaction in
            let matchesSearch = searchText.isEmpty || 
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText)
            
            let matchesType = filterType == nil || transaction.type == filterType
            
            let matchesRecurring = filterRecurring == .all ||
                (filterRecurring == .recurring && transaction.isRecurring) ||
                (filterRecurring == .oneTime && !transaction.isRecurring)
            
            let transactionComponents = calendar.dateComponents(components, from: transaction.date)
            let matchesPeriod: Bool
            
            switch selectedPeriod {
            case .all:
                matchesPeriod = true
            case .week:
                matchesPeriod = transactionComponents.weekOfYear == currentComponents.weekOfYear &&
                               transactionComponents.year == currentComponents.year
            case .month:
                matchesPeriod = transactionComponents.month == currentComponents.month &&
                               transactionComponents.year == currentComponents.year
            case .year:
                matchesPeriod = transactionComponents.year == currentComponents.year
            }
            
            return matchesSearch && matchesType && matchesRecurring && matchesPeriod
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
                        Color.black,
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Section
                    VStack(spacing: 12) {
                        // Date Period Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(TimePeriod.allCases, id: \.self) { period in
                                    FilterPill(
                                        title: period.rawValue,
                                        icon: periodIcon(for: period),
                                        color: periodColor(for: period),
                                        isSelected: selectedPeriod == period
                                    ) {
                                        withAnimation { selectedPeriod = period }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Transaction Type Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterPill(
                                    title: "All",
                                    icon: "tray.fill",
                                    color: Color(white: 0.2),
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
                                        color: recurringColor(for: filter),
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
    
    private func periodIcon(for period: TimePeriod) -> String {
        switch period {
        case .all: return "infinity.circle"
        case .week: return "calendar.circle"
        case .month: return "calendar.circle.fill"
        case .year: return "calendar.badge.clock"
        }
    }
    
    private func periodColor(for period: TimePeriod) -> Color {
        switch period {
        case .all: return Color(white: 0.2)
        case .week: return .blue
        case .month: return .purple
        case .year: return .indigo
        }
    }
    
    private func recurringColor(for filter: RecurringFilter) -> Color {
        switch filter {
        case .all: return Color(white: 0.2)
        case .oneTime: return .orange
        case .recurring: return .blue
        }
    }
}

struct FilterPill: View {
    let title: String
    let icon: String
    var color: Color = .accentColor
    let isSelected: Bool
    let action: () -> Void
    
    private var isAllFilter: Bool {
        title == "All" || title == "All Time"
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.medium)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
        }
    }
    
    private var foregroundColor: Color {
        if isAllFilter {
            return isSelected ? .white : .white.opacity(0.9)
        }
        return isSelected ? .white : color
    }
    
    private var backgroundColor: Color {
        if isAllFilter {
            return isSelected ? color : color.opacity(0.5)
        }
        return isSelected ? color : color.opacity(0.1)
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
