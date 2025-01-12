// Bu dosya, uygulamanın ana görünüm yapısını ve sekme tabanlı navigasyonunu içerir
// Gerekli kütüphaneleri içe aktarıyoruz
import SwiftUI
import SwiftData

// Ana görünüm yapısı - Uygulamanın tüm sekmelerini ve navigasyonunu yönetir
struct ContentView: View {
    // Seçili sekmeyi takip eden durum değişkeni (0'dan başlayarak numaralandırılmış)
    @State private var selectedTab = 0
    
    // Görünüm yapısı
    var body: some View {
        // Tab görünümü - Alt kısımda sekmeleri gösterir
        TabView(selection: $selectedTab) {
            // Ana Sayfa sekmesi
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")  // Ev ikonu ile ana sayfa
                }
                .tag(0)  // Sekme indeksi
            
            // İşlemler sekmesi - Tüm gelir ve giderlerin listesi
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")  // Liste ikonu
                }
                .tag(1)
            
            // Yeni İşlem Ekleme sekmesi
            AddTransactionView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")  // Artı ikonu
                }
                .tag(2)
            
            // Analiz sekmesi - Grafik ve istatistikler
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie.fill")  // Pasta grafik ikonu
                }
                .tag(3)
            
            // Ayarlar sekmesi
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")  // Dişli çark ikonu
                }
                .tag(4)
        }
    }
} 
