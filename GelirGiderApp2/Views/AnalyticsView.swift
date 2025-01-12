import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var transactions: [Transaction]
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedChartType: ChartType = .bar
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    enum ChartType {
        case bar, pie
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    VStack(spacing: 15) {
                        // Time Period Selector
                        Picker("Time Period", selection: $selectedPeriod) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Balance Summary
                        HStack(spacing: 15) {
                            AnalyticsSummaryCard(
                                title: "Income",
                                amount: totalIncome,
                                icon: "arrow.down.circle.fill",
                                color: .green
                            )
                            
                            AnalyticsSummaryCard(
                                title: "Expenses",
                                amount: totalExpenses,
                                icon: "arrow.up.circle.fill",
                                color: .red
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Charts Section
                    VStack(spacing: 20) {
                        // Income vs Expenses Chart
                        AnalyticsCard(title: "Income vs Expenses") {
                            Chart {
                                BarMark(
                                    x: .value("Category", "Income"),
                                    y: .value("Amount", totalIncome)
                                )
                                .foregroundStyle(Color.green.gradient)
                                .cornerRadius(8)
                                
                                BarMark(
                                    x: .value("Category", "Expenses"),
                                    y: .value("Amount", totalExpenses)
                                )
                                .foregroundStyle(Color.red.gradient)
                                .cornerRadius(8)
                            }
                            .frame(height: 200)
                            .padding(.top)
                        }
                        
                        // Category Distribution
                        AnalyticsCard(title: "Expenses by Category") {
                            TabView {
                                // Bar Chart
                                Chart {
                                    ForEach(expensesByCategory, id: \.category) { item in
                                        BarMark(
                                            x: .value("Amount", item.amount),
                                            y: .value("Category", item.category)
                                        )
                                        .foregroundStyle(by: .value("Category", item.category))
                                        .cornerRadius(8)
                                    }
                                }
                                .frame(height: 250)
                                .padding(.top)
                                
                                // Pie Chart
                                Chart {
                                    ForEach(expensesByCategory, id: \.category) { item in
                                        SectorMark(
                                            angle: .value("Amount", item.amount),
                                            innerRadius: .ratio(0.618),
                                            angularInset: 1.5
                                        )
                                        .cornerRadius(8)
                                        .foregroundStyle(by: .value("Category", item.category))
                                    }
                                }
                                .frame(height: 250)
                                .padding(.top)
                            }
                            .tabViewStyle(.page)
                            .frame(height: 300)
                        }
                    }
                    
                    // Statistics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        StatisticCard(
                            title: "Daily Average",
                            value: averageDailyExpense,
                            icon: "chart.bar.fill",
                            color: .blue
                        )
                        
                        StatisticCard(
                            title: "Top Category",
                            value: mostExpensiveCategory,
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        StatisticCard(
                            title: "Savings Rate",
                            value: String(format: "%.1f%%", savingsRate),
                            icon: "leaf.fill",
                            color: .green
                        )
                        
                        StatisticCard(
                            title: "Transactions",
                            value: String(transactions.count),
                            icon: "list.bullet",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date = {
            switch selectedPeriod {
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: now) ?? now
            }
        }()
        
        return transactions.filter { $0.date >= startDate }
    }
    
    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var expensesByCategory: [(category: String, amount: Double)] {
        Dictionary(grouping: filteredTransactions.filter { $0.type == .expense }) { $0.category }
            .mapValues { transactions in
                transactions.reduce(0) { $0 + $1.amount }
            }
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    
    private var averageDailyExpense: String {
        let days = max(1, Calendar.current.dateComponents([.day], from: filteredTransactions.first?.date ?? Date(), to: Date()).day ?? 1)
        return "₺" + String(format: "%.2f", totalExpenses / Double(days))
    }
    
    private var mostExpensiveCategory: String {
        expensesByCategory.first?.category ?? "N/A"
    }
    
    private var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return ((totalIncome - totalExpenses) / totalIncome) * 100
    }
}

struct AnalyticsSummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("₺" + String(format: "%.2f", amount))
                    .font(.title3.bold())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AnalyticsCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title3.bold())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
} 