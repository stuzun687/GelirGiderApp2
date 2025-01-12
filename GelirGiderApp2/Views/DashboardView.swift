// Bu dosya, uygulamanın ana sayfa görünümünü içerir.
// Kullanıcıların gelir-gider durumlarını takip edebilecekleri, grafik ve istatistikleri görebilecekleri
// bir dashboard (gösterge paneli) sağlar.

// Gerekli kütüphaneleri içe aktarıyoruz:
// SwiftUI - Kullanıcı arayüzü bileşenleri için
// SwiftData - Veritabanı işlemleri için 
// Charts - Grafik ve istatistik gösterimleri için
import SwiftUI
import SwiftData
import Charts

// Ana sayfa görünüm yapısı - Dashboard
// Bu yapı, kullanıcının finansal durumunu genel olarak görebileceği ana ekranı oluşturur
struct DashboardView: View {
    // MARK: - Durum Değişkenleri (State Variables)
    
    // @Query ile veritabanından işlemleri çekiyoruz
    // Bu sorgu otomatik olarak güncellenecek ve UI'ı yenileyecektir
    @Query private var transactions: [Transaction]
    
    // ModelContext, veritabanı işlemleri için gerekli olan bağlamı sağlar
    // Yeni kayıt ekleme, silme, güncelleme gibi işlemler için kullanılır
    @Environment(\.modelContext) private var modelContext
    
    // Sistem renk teması için ortam değişkeni
    // Kullanıcının cihazında açık/koyu mod ayarına göre UI'ı uyarlamak için kullanılır
    @Environment(\.colorScheme) private var colorScheme
    
    // Seçili zaman periyodu için durum değişkeni
    // Kullanıcının haftalık/aylık/yıllık görünümler arasında geçiş yapmasını sağlar
    // Varsayılan olarak aylık görünüm seçilidir
    @State private var selectedPeriod: TimePeriod = .month
    
    // Seçili tarih için durum değişkeni
    // Kullanıcının farklı tarih aralıklarındaki verileri görüntülemesini sağlar
    // Varsayılan olarak bugünün tarihini gösterir
    @State private var selectedDate = Date()
    
    // MARK: - Enum Tanımlamaları
    
    // Zaman periyodu için enum tanımı
    // Kullanıcının seçebileceği farklı zaman aralıklarını belirtir
    enum TimePeriod: String, CaseIterable {
        case week = "Week"   // Haftalık görünüm seçeneği
        case month = "Month" // Aylık görünüm seçeneği
        case year = "Year"   // Yıllık görünüm seçeneği
        
        // Her periyod için uygun takvim bileşenini döndüren hesaplanmış özellik
        // Tarih hesaplamalarında ve filtrelemede kullanılır
        var component: Calendar.Component {
            switch self {
            case .week: return .weekOfYear  // Yılın kaçıncı haftası
            case .month: return .month      // Ay numarası
            case .year: return .year        // Yıl değeri
            }
        }
    }
    
    // MARK: - Hesaplanmış Özellikler (Computed Properties)
    
    // Seçili zaman periyoduna göre işlemleri filtreleyen hesaplanmış özellik
    // Bu özellik, dashboard'da gösterilecek işlemleri seçili tarihe göre filtreler
    var filteredTransactions: [Transaction] {
        // Takvim işlemleri için Calendar nesnesini al
        let calendar = Calendar.current
        
        // Tarih karşılaştırması için gerekli bileşenleri tanımla
        let components: Set<Calendar.Component> = [.year, .month, .weekOfYear]
        
        // Seçili tarihin bileşenlerini al
        let currentComponents = calendar.dateComponents(components, from: selectedDate)
        
        // İşlemleri seçili periyoda göre filtrele
        return transactions.filter { transaction in
            // Her işlemin tarih bileşenlerini al
            let transactionComponents = calendar.dateComponents(components, from: transaction.date)
            
            // Seçili periyoda göre filtreleme mantığını uygula
            switch selectedPeriod {
            case .week:  
                // Haftalık filtreleme:
                // İşlemin yılı ve haftası, seçili tarih ile aynı olmalı
                return transactionComponents.weekOfYear == currentComponents.weekOfYear &&
                       transactionComponents.year == currentComponents.year
                
            case .month:  
                // Aylık filtreleme:
                // İşlemin yılı ve ayı, seçili tarih ile aynı olmalı
                return transactionComponents.month == currentComponents.month &&
                       transactionComponents.year == currentComponents.year
                
            case .year:  
                // Yıllık filtreleme:
                // Sadece işlemin yılı, seçili tarih ile aynı olmalı
                return transactionComponents.year == currentComponents.year
            }
        }
    }
    
    // Seçili periyod için finansal özet bilgileri hesaplayan özellik
    // Toplam gelir, gider ve net bakiye değerlerini döndürür
    var periodSummary: (income: Double, expense: Double, balance: Double) {
        // Takvim işlemleri için Calendar nesnesini al
        let calendar = Calendar.current
        
        // Periyodun başlangıç tarihini tutacak değişken
        let periodStart: Date
        
        // Seçili periyoda göre başlangıç tarihini belirle
        switch selectedPeriod {
        case .week:  
            // Haftalık görünüm için son 7 günün başlangıcı
            periodStart = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
            
        case .month:  
            // Aylık görünüm için ayın ilk günü
            periodStart = calendar.startOfMonth(for: selectedDate)
            
        case .year:  
            // Yıllık görünüm için yılın ilk günü
            periodStart = calendar.startOfYear(for: selectedDate)
        }
        
        // Periyod başlangıcına kadar olan tüm işlemlerin net bakiyesini hesapla
        let initialBalance = transactions
            .filter { $0.date < periodStart }
            .reduce(0.0) { result, transaction in
                // Gelir ise ekle, gider ise çıkar
                result + (transaction.type == .income ? transaction.amount : -transaction.amount)
            }
        
        // Periyod içindeki toplam gelir ve gideri hesaplamak için değişkenler
        var income: Double = 0   // Toplam gelir
        var expense: Double = 0  // Toplam gider
        
        // Filtrelenmiş işlemleri döngüye al ve toplamları hesapla
        for transaction in filteredTransactions {
            if transaction.type == .income {
                income += transaction.amount    // Gelir ise gelire ekle
            } else {
                expense += transaction.amount   // Gider ise gidere ekle
            }
        }
        
        // Hesaplanan değerleri döndür:
        // - Toplam gelir
        // - Toplam gider
        // - Net bakiye (başlangıç bakiyesi + gelirler - giderler)
        return (income, expense, initialBalance + income - expense)
    }
    
    // MARK: - Ana Görünüm Yapısı
    
    // Görünüm yapısı - Dashboard'un ana içeriği
    // Tüm UI bileşenlerinin düzenlendiği ve görüntülendiği yer
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan için premium görünümlü siyah gradyan
                // Üst soldan alt sağa doğru koyulaşan bir efekt oluşturur
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Ana içerik - Kaydırılabilir alan
                // Kullanıcının tüm finansal bilgilerini görebileceği bölüm
                ScrollView {
                    VStack(spacing: 24) {
                        // Periyod Seçici ve Bakiye Kartı
                        // Kullanıcının zaman aralığını seçebileceği ve toplam bakiyeyi görebileceği bölüm
                        VStack(spacing: 16) {
                            // Bakiye Bölümü
                            // Toplam bakiye tutarını ve durumunu gösteren alan
                            VStack(spacing: 8) {
                                Text("Total Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(formatAmount(periodSummary.balance))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(periodSummary.balance >= 0 ? .green : .red)
                            }
                            
                            // Periyod Seçici
                            // Kullanıcının farklı zaman aralıkları arasında geçiş yapabildiği bölüm
                            VStack(spacing: 12) {
                                // Periyod Seçim Butonları
                                // Hafta/Ay/Yıl seçenekleri için butonlar
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
                                
                                // Tarih Navigasyonu
                                // İleri/geri gitme butonları ve seçili tarih gösterimi
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
                        
                        // Özet Kartları
                        // Gelir ve gider özetlerini gösteren kartlar
                        HStack(spacing: 16) {
                            // Gelir Özet Kartı
                            // Toplam geliri ve ilgili ikonu gösteren kart
                            SummaryCard(
                                title: "Income",
                                amount: periodSummary.income,
                                color: .green,
                                icon: "arrow.down.circle.fill"
                            )
                            
                            // Gider Özet Kartı
                            // Toplam gideri ve ilgili ikonu gösteren kart
                            SummaryCard(
                                title: "Expense",
                                amount: periodSummary.expense,
                                color: .red,
                                icon: "arrow.up.circle.fill"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Grafik Kartı
                        // İşlem geçmişini görsel olarak gösteren grafik
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Transaction History")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.semibold)
                            
                            // İşlem Geçmişi Grafiği
                            // Gelir ve giderlerin çubuk grafik olarak gösterimi
                            Chart {
                                ForEach(groupedTransactions, id: \.date) { group in
                                    // Gelir Çubuğu
                                    BarMark(
                                        x: .value("Date", group.dateString),
                                        y: .value("Amount", group.income),
                                        width: .fixed(20)
                                    )
                                    .foregroundStyle(.green.opacity(0.7))
                                    
                                    // Gider Çubuğu
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
                        
                        // Son İşlemler Listesi
                        // En son yapılan işlemlerin listelendiği bölüm
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
                            
                            // Son 5 işlemi listele
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
    
    // MARK: - Yardımcı Fonksiyonlar
    
    // Seçili periyod için tarih metni oluşturan hesaplanmış özellik
    // Örnek: "Week 1, 2024", "January 2024", "2024"
    private var periodDateString: String {
        let formatter = DateFormatter()
        
        switch selectedPeriod {
        case .week:  
            // Hafta formatı: "Week 1, 2024"
            formatter.dateFormat = "'Week' w, yyyy"
        case .month:  
            // Ay formatı: "January 2024"
            formatter.dateFormat = "MMMM yyyy"
        case .year:  
            // Yıl formatı: "2024"
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: selectedDate)
    }
    
    // Tarihi ileri veya geri hareket ettiren fonksiyon
    // value parametresi: hareket miktarı (+1 ileri, -1 geri)
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
    
    // Para tutarını biçimlendiren yardımcı fonksiyon
    // Örnek: ₺1,234.56
    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        return formatter.string(from: NSNumber(value: value)) ?? "₺0"
    }
    
    // İşlemleri gruplandıran hesaplanmış özellik
    // Grafik gösterimi için verileri hazırlar
    private var groupedTransactions: [(date: Date, dateString: String, income: Double, expense: Double)] {
        let calendar = Calendar.current
        var groups: [Date: (income: Double, expense: Double)] = [:]
        
        // X ekseni etiketleri için tarih biçimlendirici
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .week:  
            // Haftalık görünüm için gün kısaltmaları (Pzt, Sal, vb.)
            formatter.dateFormat = "EEE"
        case .month:  
            // Aylık görünüm için gün sayısı (1, 2, 3, vb.)
            formatter.dateFormat = "d"
        case .year:  
            // Yıllık görünüm için ay kısaltmaları (Oca, Şub, vb.)
            formatter.dateFormat = "MMM"
        }
        
        // İşlemleri tarihe göre grupla
        for transaction in filteredTransactions {
            let date: Date
            switch selectedPeriod {
            case .week:  
                // Haftalık gruplandırma - Günlük bazda
                date = calendar.startOfDay(for: transaction.date)
            case .month:  
                // Aylık gruplandırma - Günlük bazda
                date = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: transaction.date)) ?? transaction.date
            case .year:  
                // Yıllık gruplandırma - Aylık bazda
                date = calendar.date(from: calendar.dateComponents([.year, .month], from: transaction.date)) ?? transaction.date
            }
            
            // Mevcut grup değerlerini güncelle
            let current = groups[date] ?? (income: 0, expense: 0)
            if transaction.type == .income {
                groups[date] = (income: current.income + transaction.amount, expense: current.expense)
            } else {
                groups[date] = (income: current.income, expense: current.expense + transaction.amount)
            }
        }
        
        // Grupları tarihe göre sıralı dizi haline getir
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
    
    // Her periyod için renk döndüren yardımcı fonksiyon
    private func periodColor(for period: TimePeriod) -> Color {
        switch period {
        case .week: return .blue     // Hafta seçeneği için mavi renk
        case .month: return .purple  // Ay seçeneği için mor renk
        case .year: return .indigo   // Yıl seçeneği için indigo renk
        }
    }
}

// MARK: - Yardımcı Görünümler

// Özet Kartı Görünümü
// Gelir ve gider özetlerini gösteren kart bileşeni
struct SummaryCard: View {
    let title: String      // Kart başlığı (Income/Expense)
    let amount: Double     // Gösterilecek tutar
    let color: Color       // Kart rengi (yeşil/kırmızı)
    let icon: String       // Sistem ikonu adı
    
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
    
    // Para tutarını biçimlendiren yardımcı fonksiyon
    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        return formatter.string(from: NSNumber(value: value)) ?? "₺0"
    }
}

// İşlem Kartı Arka Plan Görünümü
// Kartlar için özel tasarlanmış arka plan bileşeni
struct TransactionCard: View {
    let colorScheme: ColorScheme  // Sistem renk teması (açık/koyu mod)
    
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

// MARK: - Takvim Uzantıları

// Calendar sınıfı için yardımcı uzantılar
extension Calendar {
    // Ayın başlangıç tarihini döndüren fonksiyon
    // Örnek: 15 Ocak 2024 -> 1 Ocak 2024
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    // Yılın başlangıç tarihini döndüren fonksiyon
    // Örnek: 15 Ocak 2024 -> 1 Ocak 2024
    func startOfYear(for date: Date) -> Date {
        let components = dateComponents([.year], from: date)
        return self.date(from: components) ?? date
    }
} 
