import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var transactions: [Transaction]
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedChartType: ChartType = .bar
    @State private var selectedDateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return startDate...Date()
    }()
    @State private var showDatePicker = false
    @State private var selectedInsight: InsightType = .overview
    @State private var selectedTimeRange: TimeRange = .oneMonth
    @State private var showingChartTooltip = false
    @State private var selectedDataPoint: (String, Double)? = nil
    @State private var chartScale: CGFloat = 1.0
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case custom = "Custom"
    }
    
    enum ChartType {
        case bar, pie, line
    }
    
    enum InsightType: String, CaseIterable {
        case overview = "Overview"
        case spending = "Spending"
        case trends = "Trends"
    }
    
    enum TimeRange {
        case oneMonth
        case threeMonths
        case sixMonths
        case oneYear
        
        var title: String {
            switch self {
            case .oneMonth: return "1M"
            case .threeMonths: return "3M"
            case .sixMonths: return "6M"
            case .oneYear: return "1Y"
            }
        }
        
        var months: Int {
            switch self {
            case .oneMonth: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium black background
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
                        // Insight Type Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(InsightType.allCases, id: \.self) { insight in
                                    InsightPill(
                                        title: insight.rawValue,
                                        icon: insightIcon(for: insight),
                                        isSelected: selectedInsight == insight
                                    ) {
                                        withAnimation {
                                            selectedInsight = insight
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Time Period and Date Range
                        VStack(spacing: 16) {
                            // Period Selector Pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                        PeriodPill(
                                            title: period.rawValue,
                                            isSelected: selectedPeriod == period
                                        ) {
                                            withAnimation {
                                                selectedPeriod = period
                                                if period == .custom {
                                                    showDatePicker = true
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            if showDatePicker {
                                DateRangeSelector(
                                    range: $selectedDateRange,
                                    isVisible: $showDatePicker
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        
                        // Main Analytics Content
                        Group {
                            switch selectedInsight {
                            case .overview:
                                overviewSection
                            case .spending:
                                spendingSection
                            case .trends:
                                trendsSection
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Analytics")
        }
    }
    
    // MARK: - Analytics Sections
    
    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Summary Cards with Growth Indicators
            HStack(spacing: 16) {
                AnalyticsSummaryCard(
                    title: "Income",
                    amount: totalIncome,
                    previousAmount: previousPeriodIncome,
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                AnalyticsSummaryCard(
                    title: "Expenses",
                    amount: totalExpenses,
                    previousAmount: previousPeriodExpenses,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }
            .padding(.horizontal)
            
            // Use the new balance trend card
            balanceTrendCard
            
            // Enhanced Statistics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatisticCard(
                    title: "Daily Average",
                    value: averageDailyExpense,
                    previousValue: previousAverageDailyExpense,
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Top Category",
                    value: mostExpensiveCategory,
                    previousValue: categoryPercentage,
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatisticCard(
                    title: "Savings Rate",
                    value: String(format: "%.1f%%", savingsRate),
                    previousValue: String(format: "%.1f%%", previousSavingsRate),
                    icon: "leaf.fill",
                    color: .green
                )
                
                StatisticCard(
                    title: "Transactions",
                    value: String(transactions.count),
                    previousValue: transactionTrend,
                    icon: "list.bullet",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var spendingSection: some View {
        VStack(spacing: 20) {
            // Category Distribution with Enhanced Details
            AnalyticsCard(title: "Spending by Category") {
                TabView {
                    // Enhanced Pie Chart
                    VStack {
                        Chart {
                            ForEach(expensesByCategory, id: \.category) { item in
                                SectorMark(
                                    angle: .value("Amount", item.amount),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1.5
                                )
                                .cornerRadius(8)
                                .foregroundStyle(by: .value("Category", item.category))
                                .annotation(position: .overlay) {
                                    VStack {
                                        Text(item.category)
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                        Text("\(Int((item.amount / totalExpenses) * 100))%")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .frame(height: 300)
                        
                        // Category Legend with Details
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(expensesByCategory, id: \.category) { item in
                                    HStack {
                                        Circle()
                                            .fill(categoryColor(for: item.category))
                                            .frame(width: 8, height: 8)
                                        Text(item.category)
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text("₺\(Int(item.amount))")
                                                .fontWeight(.medium)
                                            Text("\(Int((item.amount / totalExpenses) * 100))%")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 100)
                    }
                    
                    // Enhanced Bar Chart
                    VStack {
                        Chart {
                            ForEach(expensesByCategory, id: \.category) { item in
                                BarMark(
                                    x: .value("Category", item.category),
                                    y: .value("Amount", item.amount)
                                )
                                .foregroundStyle(by: .value("Category", item.category))
                                .annotation(position: .top) {
                                    VStack {
                                        Text("₺\(Int(item.amount))")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        Text("\(Int((item.amount / totalExpenses) * 100))%")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .frame(height: 300)
                        
                        // Trend Indicators
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(expensesByCategory, id: \.category) { item in
                                    VStack(spacing: 4) {
                                        Text(item.category)
                                            .font(.caption)
                                        HStack(spacing: 4) {
                                            Image(systemName: getCategoryTrendIcon(for: item.category))
                                                .foregroundColor(getCategoryTrendColor(for: item.category))
                                            Text(getCategoryTrendPercentage(for: item.category))
                                                .font(.caption2)
                                                .foregroundColor(getCategoryTrendColor(for: item.category))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6).opacity(0.1))
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 450)
            }
            
            // Enhanced Daily Spending Pattern
            AnalyticsCard(title: "Daily Spending Pattern") {
                VStack(spacing: 16) {
                    Chart {
                        ForEach(spendingByDayOfWeek, id: \.day) { item in
                            BarMark(
                                x: .value("Day", item.day),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .annotation(position: .top) {
                                Text("₺\(Int(item.amount))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    
                    // Day Analysis
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Highest Spending Day")
                                .font(.subheadline)
                            Spacer()
                            Text(highestSpendingDay)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Lowest Spending Day")
                                .font(.subheadline)
                            Spacer()
                            Text(lowestSpendingDay)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6).opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var trendsSection: some View {
        VStack(spacing: 20) {
            // Monthly Comparison
            AnalyticsCard(title: "Aylık Karşılaştırma") {
                VStack(spacing: 16) {
                    Chart {
                        ForEach(monthlyComparison, id: \.month) { item in
                            BarMark(
                                x: .value("Ay", item.month),
                                y: .value("Gelir", item.income)
                            )
                            .foregroundStyle(.green.opacity(0.7))
                            
                            BarMark(
                                x: .value("Ay", item.month),
                                y: .value("Gider", -item.expenses)
                            )
                            .foregroundStyle(.red.opacity(0.7))
                        }
                    }
                    .frame(height: 250)
                    
                    // Explanation text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grafik Açıklaması:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("• Yeşil çubuklar aylık gelirleri gösterir")
                        Text("• Kırmızı çubuklar aylık giderleri gösterir")
                        Text("• Çubukların yüksekliği tutarı temsil eder")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color(.systemGray6).opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Category Trends with Predictions
            AnalyticsCard(title: "Kategori Trendleri ve Tahminler") {
                VStack(spacing: 16) {
                    Chart {
                        ForEach(categoryTrends, id: \.category) { trend in
                            LineMark(
                                x: .value("Ay", trend.month),
                                y: .value("Tutar", trend.amount)
                            )
                            .foregroundStyle(by: .value("Kategori", trend.category))
                            .symbol(by: .value("Kategori", trend.category))
                        }
                    }
                    .frame(height: 250)
                    .chartLegend(position: .bottom)
                    
                    // Trend Analysis
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trend Analizi")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(expensesByCategory.prefix(3), id: \.category) { category in
                            HStack {
                                Circle()
                                    .fill(categoryColor(for: category.category))
                                    .frame(width: 8, height: 8)
                                
                                Text(category.category)
                                    .font(.caption)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: getCategoryTrendIcon(for: category.category))
                                    Text(getCategoryTrendPercentage(for: category.category))
                                }
                                .foregroundColor(getCategoryTrendColor(for: category.category))
                                .font(.caption)
                            }
                            
                            if let prediction = predictNextMonthExpense(for: category.category) {
                                Text("Gelecek Ay Tahmini: ₺\(Int(prediction))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func insightIcon(for type: InsightType) -> String {
        switch type {
        case .overview: return "chart.pie.fill"
        case .spending: return "cart.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        }
    }
    
    // MARK: - Data Calculations
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .month, value: -12, to: now) ?? now
        case .custom:
            startDate = selectedDateRange.lowerBound
        }
        
        return transactions
            .filter { $0.date >= startDate && $0.date <= now }
            .sorted { $0.date < $1.date }
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
    
    private var dailyBalances: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        var balances: [(date: Date, amount: Double)] = []
        var runningBalance: Double = 0
        
        // Get start and end dates
        let now = Date()
        let startDate: Date
        
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .month, value: -12, to: now) ?? now
        case .custom:
            startDate = selectedDateRange.lowerBound
        }
        
        // Create date range
        var currentDate = calendar.startOfDay(for: startDate)
        let endDate = calendar.startOfDay(for: now)
        
        // Get initial balance (sum of all transactions before start date)
        runningBalance = transactions
            .filter { $0.date < startDate }
            .reduce(0) { result, transaction in
                result + (transaction.type == .income ? transaction.amount : -transaction.amount)
            }
        
        // Calculate daily balances
        while currentDate <= endDate {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            
            // Get transactions for current day
            let dayTransactions = transactions.filter {
                let transactionDate = calendar.startOfDay(for: $0.date)
                return transactionDate == currentDate
            }
            
            // Update running balance with day's transactions
            for transaction in dayTransactions {
                runningBalance += transaction.type == .income ? transaction.amount : -transaction.amount
            }
            
            // Add balance point for the day
            balances.append((currentDate, runningBalance))
            
            currentDate = nextDate
        }
        
        return balances
    }
    
    private var filteredDailyBalances: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        // Determine the start date based on selected period
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .custom:
            startDate = selectedDateRange.lowerBound
        }
        
        // Calculate total balance from all transactions before start date
        let initialBalance = transactions
            .filter { $0.date < startDate }
            .reduce(0.0) { result, transaction in
                result + (transaction.type == .income ? transaction.amount : -transaction.amount)
            }
        
        // Create continuous date range with cumulative balances
        var balances: [(date: Date, amount: Double)] = []
        var runningBalance = initialBalance
        var currentDate = calendar.startOfDay(for: startDate)
        let endDate = calendar.startOfDay(for: now)
        
        // Create a dictionary of daily transactions for faster lookup
        let dailyTransactions = Dictionary(grouping: transactions.filter { $0.date >= startDate && $0.date <= endDate }) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        
        // Add initial balance point
        balances.append((currentDate, runningBalance))
        
        // Iterate through each day in the range
        while currentDate <= endDate {
            // Process transactions for the current day if any exist
            if let dayTransactions = dailyTransactions[currentDate] {
                for transaction in dayTransactions.sorted(by: { $0.date < $1.date }) {
                    runningBalance += transaction.type == .income ? transaction.amount : -transaction.amount
                }
            }
            
            // Always add a balance point for the day, even if there were no transactions
            balances.append((currentDate, runningBalance))
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return balances
    }
    
    private var spendingByDayOfWeek: [(day: String, amount: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        var spending: [Int: Double] = [:]
        
        for transaction in filteredTransactions where transaction.type == .expense {
            let weekday = calendar.component(.weekday, from: transaction.date)
            spending[weekday, default: 0] += transaction.amount
        }
        
        return (1...7).map { weekday in
            let date = calendar.date(bySetting: .weekday, value: weekday, of: Date()) ?? Date()
            return (formatter.string(from: date), spending[weekday] ?? 0)
        }
    }
    
    private var monthlyComparison: [(month: String, income: Double, expenses: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        var comparison: [Int: (income: Double, expenses: Double)] = [:]
        
        for transaction in filteredTransactions {
            let month = calendar.component(.month, from: transaction.date)
            var current = comparison[month] ?? (income: 0, expenses: 0)
            
            if transaction.type == .income {
                current.income += transaction.amount
            } else {
                current.expenses += transaction.amount
            }
            
            comparison[month] = current
        }
        
        return comparison.map { month, values in
            let date = calendar.date(from: DateComponents(month: month)) ?? Date()
            return (formatter.string(from: date), values.income, values.expenses)
        }.sorted { $0.month < $1.month }
    }
    
    private var categoryTrends: [(category: String, month: String, amount: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        var trends: [(category: String, month: Int, amount: Double)] = []
        
        for category in Set(transactions.map(\.category)) {
            var monthlyAmounts: [Int: Double] = [:]
            
            for transaction in filteredTransactions where transaction.category == category {
                let month = calendar.component(.month, from: transaction.date)
                monthlyAmounts[month, default: 0] += transaction.amount
            }
            
            for (month, amount) in monthlyAmounts {
                trends.append((category: category, month: month, amount: amount))
            }
        }
        
        return trends.map { trend in
            let date = calendar.date(from: DateComponents(month: trend.month)) ?? Date()
            return (trend.category, formatter.string(from: date), trend.amount)
        }.sorted { $0.month < $1.month }
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
    
    private var previousPeriodIncome: Double {
        let previousTransactions = getPreviousPeriodTransactions()
        return previousTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var previousPeriodExpenses: Double {
        let previousTransactions = getPreviousPeriodTransactions()
        return previousTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var previousAverageDailyExpense: String {
        let previousTransactions = getPreviousPeriodTransactions()
        let days = max(1, Calendar.current.dateComponents([.day], from: previousTransactions.first?.date ?? Date(), to: Date()).day ?? 1)
        return "₺" + String(format: "%.2f", previousTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } / Double(days))
    }
    
    private var previousSavingsRate: Double {
        let previousTransactions = getPreviousPeriodTransactions()
        let income = previousTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expenses = previousTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        guard income > 0 else { return 0 }
        return ((income - expenses) / income) * 100
    }
    
    private var categoryPercentage: String {
        guard let topCategory = expensesByCategory.first else { return "" }
        return String(format: "%.1f%% of expenses", (topCategory.amount / totalExpenses) * 100)
    }
    
    private var transactionTrend: String {
        let previousCount = getPreviousPeriodTransactions().count
        let currentCount = transactions.count
        let change = ((Double(currentCount) - Double(previousCount)) / Double(previousCount)) * 100
        return String(format: "%.1f%% vs last period", change)
    }
    
    private func getPreviousPeriodTransactions() -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let currentStart: Date
        let previousStart: Date
        let previousEnd: Date
        
        switch selectedPeriod {
        case .week:
            currentStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            previousStart = calendar.date(byAdding: .day, value: -14, to: currentStart) ?? currentStart
            previousEnd = currentStart
        case .month:
            currentStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            previousStart = calendar.date(byAdding: .month, value: -1, to: currentStart) ?? currentStart
            previousEnd = currentStart
        case .year:
            currentStart = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            previousStart = calendar.date(byAdding: .year, value: -1, to: currentStart) ?? currentStart
            previousEnd = currentStart
        case .custom:
            let range = selectedDateRange.upperBound.timeIntervalSince(selectedDateRange.lowerBound)
            currentStart = selectedDateRange.lowerBound
            previousStart = calendar.date(byAdding: .second, value: -Int(range), to: currentStart) ?? currentStart
            previousEnd = currentStart
        }
        
        return transactions.filter { $0.date >= previousStart && $0.date < previousEnd }
    }
    
    private func getDataPoint(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> (Date, Double)? {
        let xPosition = location.x / geometry.size.width
        
        guard let date = proxy.value(atX: xPosition) as Date? else { return nil }
        
        let closest = filteredDailyBalances.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
        
        return closest.map { ($0.date, $0.amount) }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Additional Helper Methods
    
    private var highestSpendingDay: String {
        spendingByDayOfWeek.max { $0.amount < $1.amount }?.day ?? "N/A"
    }
    private func getMonthlyAmounts(for category: String) -> [Double] {
        let calendar = Calendar.current
        var amounts: [Double] = []
        var currentDate = calendar.startOfDay(for: Date())
        
        for _ in 0..<6 {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? currentDate
            
            let monthAmount = transactions
                .filter { $0.category == category && $0.type == .expense && ($0.date >= monthStart && $0.date <= monthEnd) }
                .reduce(0) { $0 + $1.amount }
            
            amounts.append(monthAmount)
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        }
        
        return amounts
    }
    private var lowestSpendingDay: String {
        spendingByDayOfWeek.min { $0.amount < $1.amount }?.day ?? "N/A"
    }
    
    private func categoryColor(for category: String) -> Color {
        // Implement consistent color mapping for categories
        let colors: [Color] = [.blue, .purple, .green, .orange, .yellow, .red, .pink, .indigo]
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
    
    private func getCategoryTrendIcon(for category: String) -> String {
        let trend = calculateCategoryTrend(for: category)
        if trend > 10 {
            return "arrow.up.right.circle.fill"
        } else if trend < -10 {
            return "arrow.down.right.circle.fill"
        } else {
            return "arrow.right.circle.fill"
        }
    }
    
    private func getCategoryTrendColor(for category: String) -> Color {
        let trend = calculateCategoryTrend(for: category)
        if trend > 10 {
            return .red
        } else if trend < -10 {
            return .green
        } else {
            return .gray
        }
    }
    
    private func getCategoryTrendPercentage(for category: String) -> String {
        let trend = calculateCategoryTrend(for: category)
        return String(format: "%.1f%%", abs(trend))
    }
    
    private func calculateCategoryTrend(for category: String) -> Double {
        let amounts = getMonthlyAmounts(for: category)
        guard amounts.count >= 2,
              let current = amounts.last,
              let previous = amounts.dropLast().last,
              previous > 0 else { return 0 }
        
        return ((current - previous) / previous) * 100
    }
    
    // Enhanced Balance Trend Card
    private var balanceTrendCard: some View {
        AnalyticsCard(title: "Balance Trend") {
            VStack(spacing: 16) {
                // Balance Statistics
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Balance")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(formatAmount(currentBalance))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(currentBalance >= 0 ? Color.green : Color.red)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Period Change")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack(spacing: 4) {
                            Image(systemName: balanceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(formatAmount(abs(balanceChange)))
                        }
                        .font(.headline)
                        .foregroundColor(balanceChange >= 0 ? Color.green : Color.red)
                    }
                }
                .padding(.horizontal)
                
                // Enhanced Chart
                let balances = filteredDailyBalances // Cache the computation
                if !balances.isEmpty {
                    Chart(balances, id: \.date) { balance in
                        LineMark(
                            x: .value("Date", balance.date),
                            y: .value("Balance", balance.amount)
                        )
                        .foregroundStyle(balance.amount >= 0 ? Color.green : Color.red)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Date", balance.date),
                            y: .value("Balance", balance.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    (balance.amount >= 0 ? Color.green : Color.red).opacity(0.15),
                                    (balance.amount >= 0 ? Color.green : Color.red).opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                                .foregroundStyle(Color.gray.opacity(0.2))
                            AxisValueLabel {
                                if let doubleValue = value.as(Double.self) {
                                    Text(formatAmount(doubleValue))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        let strideCount: Int
                        switch selectedPeriod {
                        case .week:
                            strideCount = 1  // Show every day
                        case .month:
                            strideCount = 5  // Show every 5th day
                        case .year:
                            strideCount = 30 // Show every month
                        case .custom:
                            strideCount = 5  // Show every 5th day
                        }
                        
                        return AxisMarks(preset: .aligned, values: .stride(by: .day, count: strideCount)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(getFormattedDate(date))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                AxisGridLine()
                                    .foregroundStyle(Color.gray.opacity(0.2))
                            }
                        }
                    }
                    .frame(height: 220)
                    .chartYScale(domain: .automatic(includesZero: true))  // Always include zero in the scale
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if let (date, amount) = getDataPoint(at: value.location, proxy: proxy, geometry: geometry) {
                                                selectedDataPoint = (formatDate(date), amount)
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedDataPoint = nil
                                        }
                                )
                        }
                    }
                }
                
                if let selected = selectedDataPoint {
                    HStack(spacing: 12) {
                        Text(selected.0)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formatAmount(selected.1))
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(selected.1 >= 0 ? Color.green : Color.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6).opacity(0.8))
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        return formatter.string(from: NSNumber(value: value)) ?? "₺0"
    }
    
    private func getFormattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d"  // Just show day number for month view
        case .year:
            formatter.dateFormat = "MMM"
        case .custom:
            formatter.dateFormat = "d MMM"
        }
        
        return formatter.string(from: date)
    }
    
    private var currentBalance: Double {
        filteredDailyBalances.last?.amount ?? 0
    }
    
    private var balanceChange: Double {
        guard let lastBalance = filteredDailyBalances.last?.amount,
              let firstBalance = filteredDailyBalances.first?.amount else {
            return 0
        }
        return lastBalance - firstBalance
    }
    
    // Add prediction function
    private func predictNextMonthExpense(for category: String) -> Double? {
        let amounts = getMonthlyAmounts(for: category)
        guard amounts.count >= 2 else { return nil }
        
        // Simple trend-based prediction
        let trend = calculateCategoryTrend(for: category)
        let lastAmount = amounts.last ?? 0
        
        return lastAmount * (1 + (trend / 100))
    }
}

// MARK: - Supporting Views

struct InsightPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                    .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8)
            )
        }
    }
}

struct PeriodPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple : Color.gray.opacity(0.2))
                        .shadow(color: isSelected ? .purple.opacity(0.3) : .clear, radius: 8)
                )
        }
    }
}

struct DateRangeSelector: View {
    @Binding var range: ClosedRange<Date>
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Select Date Range")
                    .font(.headline)
                Spacer()
                Button(action: { withAnimation { isVisible = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            DatePicker("Start Date", selection: Binding(
                get: { range.lowerBound },
                set: { range = $0...range.upperBound }
            ), displayedComponents: .date)
            
            DatePicker("End Date", selection: Binding(
                get: { range.upperBound },
                set: { range = range.lowerBound...$0 }
            ), displayedComponents: .date)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
        .padding(.horizontal)
    }
}

struct BudgetProgressCard: View {
    let category: String
    let spent: Double
    let total: Double
    
    private var progress: Double {
        min(spent / total, 1.0)
    }
    
    private var progressColor: Color {
        if progress < 0.7 {
            return .green
        } else if progress < 0.9 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var remainingAmount: Double {
        max(total - spent, 0)
    }
    
    private var statusMessage: String {
        if progress >= 1.0 {
            return "Bütçe aşıldı! Harcamalarınızı gözden geçirin."
        } else if progress >= 0.9 {
            return "Dikkat: Bütçe limitine yaklaşıldı!"
        } else if progress >= 0.7 {
            return "Uyarı: Bütçenin \(Int(progress * 100))%'i kullanıldı"
        } else {
            return "İyi gidiyorsunuz! Bütçe kontrolü sağlanıyor"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category)
                    .font(.headline)
                Spacer()
                Text("₺\(Int(spent)) / ₺\(Int(total))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: progress)
                .tint(progressColor)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(Int(progress * 100))% kullanıldı")
                    .font(.subheadline)
                    .foregroundColor(progressColor)
                
                Text("Kalan Bütçe: ₺\(Int(remainingAmount))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(progressColor)
                    .padding(.top, 4)
            }
            
            if progress >= 0.7 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(progressColor)
                    Text("Tasarruf önerisi: Harcamalarınızı kategorize edip önceliklendirin")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

struct AnalyticsSummaryCard: View {
    let title: String
    let amount: Double
    let previousAmount: Double
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
                    .foregroundColor(.white)
            }
            
            Text("₺" + String(format: "%.2f", previousAmount))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
        )
    }
}

struct AnalyticsCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
        )
        .padding(.horizontal)
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let previousValue: String
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
                    .foregroundColor(.white)
            }
            
            Text(previousValue)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
        )
    }
} 
