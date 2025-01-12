// Bu dosya, uygulamanın işlem listesi görünümünü içerir.
// İşlem listesi, kullanıcının tüm gelir ve giderlerini görüntüleyebileceği, 
// filtreleyebileceği ve yönetebileceği ana ekrandır.

// Gerekli kütüphaneleri içe aktarıyoruz
import SwiftUI  // Kullanıcı arayüzü bileşenleri için
import SwiftData // Veritabanı işlemleri için

// MARK: - Ana Görünüm Yapısı

// İşlem listesi görünüm yapısı - Tüm gelir ve gider işlemlerini listeler ve yönetir
struct TransactionsView: View {
    // MARK: - Veri ve Ortam Değişkenleri
    
    // Veritabanından işlemleri çeken sorgu - Tüm işlemleri otomatik olarak günceller
    @Query private var transactions: [Transaction]
    
    // Veri modeli bağlamı - Veritabanı işlemleri için gerekli (silme, güncelleme vb.)
    @Environment(\.modelContext) private var modelContext
    
    // Sistem renk teması (açık/koyu mod) - Arayüz renklerini otomatik ayarlar
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Durum Değişkenleri (State Variables)
    
    // Arama ve Filtreleme Durumları
    @State private var searchText = ""  // Kullanıcının arama çubuğuna yazdığı metin
    @State private var filterType: TransactionType?  // Seçili işlem tipi filtresi (gelir/gider)
    @State private var filterRecurring: RecurringFilter = .all  // Tekrarlanan işlem filtresi durumu
    @State private var showingSortOptions = false  // Sıralama seçenekleri menüsünün gösterim durumu
    @State private var sortOrder: SortOrder = .dateDescending  // Aktif sıralama düzeni
    @State private var selectedPeriod: TimePeriod = .all  // Seçili zaman periyodu (hafta/ay/yıl/tümü)
    @State private var selectedDate = Date()  // Seçili tarih - Filtreleme için kullanılır
    
    // MARK: - Enum Tanımlamaları
    
    // Sıralama seçenekleri için enum - İşlemlerin nasıl sıralanacağını belirler
    enum SortOrder {
        case dateDescending    // En yeniden en eskiye
        case dateAscending     // En eskiden en yeniye
        case amountDescending  // En yüksek tutardan en düşüğe
        case amountAscending   // En düşük tutardan en yükseğe
    }
    
    // Tekrarlanan işlem filtresi için enum - İşlemleri tekrarlanma durumuna göre filtreler
    enum RecurringFilter {
        case all       // Tüm işlemleri göster
        case oneTime   // Sadece tek seferlik işlemleri göster
        case recurring // Sadece tekrarlanan işlemleri göster
        
        // Her filtre seçeneği için başlık metni
        var title: String {
            switch self {
            case .all: return "All"        // Tüm işlemler
            case .oneTime: return "One-time"  // Tek seferlik işlemler
            case .recurring: return "Recurring" // Tekrarlanan işlemler
            }
        }
        
        // Her filtre seçeneği için sistem ikonu
        var icon: String {
            switch self {
            case .all: return "list.bullet"     // Tüm işlemler için liste ikonu
            case .oneTime: return "1.circle"    // Tek seferlik işlemler için 1 rakamı
            case .recurring: return "repeat.circle" // Tekrarlanan işlemler için döngü ikonu
            }
        }
    }
    
    // Zaman periyodu seçenekleri için enum - İşlemleri tarih aralığına göre filtreler
    enum TimePeriod: String, CaseIterable {
        case all = "All Time"     // Tüm zamanlar - Hiç filtreleme yapma
        case week = "This Week"   // Bu hafta - Son 7 günlük işlemler
        case month = "This Month" // Bu ay - İçinde bulunulan ayın işlemleri
        case year = "This Year"   // Bu yıl - İçinde bulunulan yılın işlemleri
        
        // Her periyod için uygun takvim bileşeni - Tarihleri karşılaştırmak için kullanılır
        var component: Calendar.Component {
            switch self {
            case .all: return .era         // Tüm zamanlar için özel değer
            case .week: return .weekOfYear // Haftalık karşılaştırma için
            case .month: return .month     // Aylık karşılaştırma için
            case .year: return .year       // Yıllık karşılaştırma için
            }
        }
    }
    
    // MARK: - Hesaplanmış Özellikler (Computed Properties)
    
    // Tüm filtreleri uygulayarak işlemleri filtreleyen ve sıralayan özellik
    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .weekOfYear]
        let currentComponents = calendar.dateComponents(components, from: selectedDate)
        
        // İşlemleri filtrele
        let filtered = transactions.filter { transaction in
            // 1. Arama metni filtrelemesi - Başlık veya kategoride arama yapar
            let matchesSearch = searchText.isEmpty || 
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText)
            
            // 2. İşlem tipi filtrelemesi - Gelir veya gider olma durumu
            let matchesType = filterType == nil || transaction.type == filterType
            
            // 3. Tekrarlanan işlem filtrelemesi - Tek seferlik veya tekrarlı olma durumu
            let matchesRecurring = filterRecurring == .all ||
                (filterRecurring == .recurring && transaction.isRecurring) ||
                (filterRecurring == .oneTime && !transaction.isRecurring)
            
            // 4. Tarih periyodu filtrelemesi
            let transactionComponents = calendar.dateComponents(components, from: transaction.date)
            let matchesPeriod: Bool
            
            // Seçili zaman periyoduna göre tarihi kontrol et
            switch selectedPeriod {
            case .all:  // Tüm zamanlar - Filtreleme yapma
                matchesPeriod = true
            case .week:  // Bu hafta - Aynı hafta içinde mi?
                matchesPeriod = transactionComponents.weekOfYear == currentComponents.weekOfYear &&
                               transactionComponents.year == currentComponents.year
            case .month:  // Bu ay - Aynı ay içinde mi?
                matchesPeriod = transactionComponents.month == currentComponents.month &&
                               transactionComponents.year == currentComponents.year
            case .year:  // Bu yıl - Aynı yıl içinde mi?
                matchesPeriod = transactionComponents.year == currentComponents.year
            }
            
            // Tüm filtre koşullarını birleştir
            return matchesSearch && matchesType && matchesRecurring && matchesPeriod
        }
        
        // Filtrelenmiş işlemleri seçili sıralama düzenine göre sırala
        return filtered.sorted { first, second in
            switch sortOrder {
            case .dateDescending: return first.date > second.date   // En yeni en üstte
            case .dateAscending: return first.date < second.date    // En eski en üstte
            case .amountDescending: return first.amount > second.amount  // En yüksek tutar en üstte
            case .amountAscending: return first.amount < second.amount   // En düşük tutar en üstte
            }
        }
    }
    
    // İşlemleri aylara göre gruplandıran özellik - Liste görünümü için
    var groupedTransactions: [(String, [Transaction])] {
        // İşlemleri ay ve yıla göre grupla
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"  // "Ocak 2024" formatında
            return formatter.string(from: transaction.date)
        }
        // Grupları tarihe göre azalan sırada sırala (en yeni ay en üstte)
        return grouped.sorted { $0.key > $1.key }
    }
    
    // MARK: - Ana Görünüm Yapısı
    
    // Görünümün ana yapısı - Kullanıcı arayüzünün tamamı
    var body: some View {
        NavigationView {
            ZStack {
                // Premium siyah arka plan gradyanı
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
                    // MARK: - Filtre Bölümü
                    
                    // Üst kısımdaki filtre seçenekleri
                    VStack(spacing: 12) {
                        // 1. Tarih Periyodu Filtresi - Yatay kaydırmalı
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
                        
                        // 2. İşlem Tipi Filtresi - Gelir/Gider seçimi
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Tümü Filtresi - Hiç filtreleme yapma
                                FilterPill(
                                    title: "All",
                                    icon: "tray.fill",
                                    color: Color(white: 0.2),
                                    isSelected: filterType == nil
                                ) {
                                    withAnimation { filterType = nil }
                                }
                                
                                // Gelir Filtresi - Sadece gelirleri göster
                                FilterPill(
                                    title: "Income",
                                    icon: "arrow.down.circle.fill",
                                    color: .green,
                                    isSelected: filterType == .income
                                ) {
                                    withAnimation { filterType = .income }
                                }
                                
                                // Gider Filtresi - Sadece giderleri göster
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
                        
                        // 3. Tekrarlanan İşlem Filtresi - Tek seferlik/Tekrarlı seçimi
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
                    
                    // MARK: - İşlemler Listesi
                    
                    // Filtrelenmiş ve gruplandırılmış işlemlerin listesi
                    ScrollView {
                        LazyVStack(spacing: 24, pinnedViews: .sectionHeaders) {
                            ForEach(groupedTransactions, id: \.0) { month, transactions in
                                Section {
                                    // Her ay için işlem listesi
                                    VStack(spacing: 16) {
                                        ForEach(transactions) { transaction in
                                            // İşlem satırı - Uzun basınca menü gösterir
                                            TransactionRow(transaction: transaction)
                                                .contextMenu {
                                                    // Silme butonu
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
                                    // Ay başlığı - Üstte sabit kalır
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
            .navigationTitle("Transactions")  // Sayfa başlığı
            .searchable(text: $searchText, prompt: "Search transactions")  // Arama çubuğu
            .toolbar {
                // Sıralama seçenekleri menüsü
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
    
    // MARK: - Yardımcı Fonksiyonlar
    
    // İşlem silme fonksiyonu
    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)  // Veritabanından sil
    }
    
    // Her periyod için uygun ikonu döndüren fonksiyon
    private func periodIcon(for period: TimePeriod) -> String {
        switch period {
        case .all: return "infinity.circle"  // Sonsuz işareti
        case .week: return "calendar.circle"  // Takvim ikonu
        case .month: return "calendar.circle.fill"  // Dolu takvim ikonu
        case .year: return "calendar.badge.clock"  // Saatli takvim ikonu
        }
    }
    
    // Her periyod için uygun rengi döndüren fonksiyon
    private func periodColor(for period: TimePeriod) -> Color {
        switch period {
        case .all: return Color(white: 0.2)  // Koyu gri
        case .week: return .blue   // Mavi
        case .month: return .purple  // Mor
        case .year: return .indigo  // İndigo
        }
    }
    
    // Her tekrarlama filtresi için uygun rengi döndüren fonksiyon
    private func recurringColor(for filter: RecurringFilter) -> Color {
        switch filter {
        case .all: return Color(white: 0.2)  // Koyu gri
        case .oneTime: return .orange  // Turuncu
        case .recurring: return .blue  // Mavi
        }
    }
}

// MARK: - Yardımcı Görünümler

// Filtre seçeneği görünümü - Yuvarlak kenarlı buton
struct FilterPill: View {
    let title: String  // Filtre başlığı
    let icon: String   // Sistem ikonu
    var color: Color = .accentColor  // Filtre rengi
    let isSelected: Bool  // Seçili durumu
    let action: () -> Void  // Tıklama aksiyonu
    
    // "All" filtresini kontrol etmek için
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
    
    // Metin rengi - Seçili duruma göre değişir
    private var foregroundColor: Color {
        if isAllFilter {
            return isSelected ? .white : .white.opacity(0.9)
        }
        return isSelected ? .white : color
    }
    
    // Arka plan rengi - Seçili duruma göre değişir
    private var backgroundColor: Color {
        if isAllFilter {
            return isSelected ? color : color.opacity(0.5)
        }
        return isSelected ? color : color.opacity(0.1)
    }
}

// İşlem satırı görünümü - Her bir işlemi gösteren kart
struct TransactionRow: View {
    let transaction: Transaction  // Gösterilecek işlem
    @Environment(\.colorScheme) private var colorScheme  // Sistem renk teması
    
    var body: some View {
        HStack(spacing: 16) {
            // Kategori İkonu
            ZStack {
                Circle()
                    .fill(transaction.type == .expense ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: getCategoryIcon(transaction.category))
                    .font(.title2)
                    .foregroundColor(transaction.type == .expense ? .red : .green)
            }
            
            // İşlem Detayları
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
            
            // Tutar ve Tarih
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
    
    // Kategori ikonunu döndüren yardımcı fonksiyon
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
    
    // Para tutarını biçimlendiren yardımcı fonksiyon
    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        return formatter.string(from: NSNumber(value: value)) ?? "₺0"
    }
    
    // Tarihi biçimlendiren yardımcı fonksiyon
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// Tekrarlanan işlem rozeti görünümü
struct RecurringBadge: View {
    let type: RecurringType  // Tekrarlanma türü
    
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
