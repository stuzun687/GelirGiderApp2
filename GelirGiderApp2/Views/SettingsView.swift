// Bu dosya, uygulamanın ayarlar görünümünü içerir
// Gerekli kütüphaneleri içe aktarıyoruz
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Ayarlar görünüm yapısı - Uygulama tercihlerini ve veri yönetimini içerir
struct SettingsView: View {
    // Veritabanından işlemleri çeken sorgu (tarihe göre tersten sıralı)
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    // Veri modeli bağlamı
    @Environment(\.modelContext) private var modelContext
    
    // Uygulama tercihleri için kalıcı depolama
    @AppStorage("defaultCurrency") private var defaultCurrency = "₺"  // Varsayılan para birimi
    @AppStorage("isDarkMode") private var isDarkMode = false  // Karanlık mod durumu
    
    // Bildirim yöneticisi
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Görünüm durumları
    @State private var showingExportSheet = false  // Veri dışa aktarma sayfası gösterimi
    @State private var showingClearDataAlert = false  // Veri temizleme onayı gösterimi
    @State private var exportData: String = ""  // Dışa aktarılacak veri
    @State private var isProcessingNotifications = false  // Bildirim işlemi durumu
    @State private var exportURL: URL?  // Dışa aktarma dosyası URL'i
    
    // Ana görünüm yapısı
    var body: some View {
        NavigationView {
            List {
                // Uygulama Tercihleri Bölümü
                Section {
                    // Para Birimi Seçici
                    HStack {
                        SettingIcon(icon: "dollarsign.circle.fill", color: .blue)
                        Picker("Currency", selection: $defaultCurrency) {
                            Text("₺ (TRY)").tag("₺")  // Türk Lirası
                            Text("$ (USD)").tag("$")  // Amerikan Doları
                            Text("€ (EUR)").tag("€")  // Euro
                        }
                    }
                    
                    // Tema Değiştirici
                    HStack {
                        SettingIcon(icon: "moon.circle.fill", color: .purple)
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }
                    
                    // Bildirim Ayarları
                    HStack {
                        SettingIcon(icon: "bell.circle.fill", color: .red)
                        if isProcessingNotifications {
                            HStack {
                                Text("Notifications")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Toggle("Notifications", isOn: Binding(
                                get: { notificationManager.isNotificationsEnabled },
                                set: { newValue in
                                    if newValue {
                                        requestNotificationPermission()  // Bildirim izni iste
                                    } else {
                                        disableNotifications()  // Bildirimleri devre dışı bırak
                                    }
                                }
                            ))
                        }
                    }
                    
                    // Bildirim Durumu ve Test
                    if notificationManager.isNotificationsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications are enabled")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            // Test bildirimi gönderme butonu
                            Button(action: sendTestNotification) {
                                HStack {
                                    Image(systemName: "bell.badge")
                                    Text("Send Test Notification (5s)")
                                }
                                .foregroundColor(.blue)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isProcessingNotifications)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications are disabled")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            // Ayarları açma butonu
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Text("Open Settings")
                                    .font(.caption)
                            }
                        }
                    }
                } header: {
                    Text("App Preferences")
                }
                
                // Veri Yönetimi Bölümü
                Section {
                    // Veri Dışa Aktarma
                    Button(action: {
                        Task {
                            await prepareExport()
                        }
                    }) {
                        HStack {
                            SettingIcon(icon: "square.and.arrow.up.circle.fill", color: .blue)
                            Text("Export Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Veri Temizleme
                    Button(action: { showingClearDataAlert = true }) {
                        HStack {
                            SettingIcon(icon: "trash.circle.fill", color: .red)
                            Text("Clear All Data")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("Data Management")
                }
                
                // Hakkında Bölümü
                Section {
                    // Versiyon Bilgisi
                    HStack {
                        SettingIcon(icon: "info.circle.fill", color: .blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    // Uygulamayı Değerlendir
                    Link(destination: URL(string: "https://apps.apple.com")!) {
                        HStack {
                            SettingIcon(icon: "star.circle.fill", color: .yellow)
                            Text("Rate App")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Gizlilik Politikası
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            SettingIcon(icon: "lock.circle.fill", color: .gray)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Kullanım Koşulları
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            SettingIcon(icon: "doc.circle.fill", color: .gray)
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(isDarkMode ? .dark : .light)
            // Veri temizleme onay uyarısı
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("Are you sure you want to clear all data? This action cannot be undone.")
            }
            // Veri dışa aktarma sayfası
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                        .navigationTitle("Export Data")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    // Veri dışa aktarma hazırlığı
    private func prepareExport() async {
        do {
            // Tüm işlemleri çekmek için tanımlayıcı oluştur
            let descriptor = FetchDescriptor<Transaction>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            // Model bağlamını kullanarak tüm işlemleri çek
            let allTransactions = try modelContext.fetch(descriptor)
            
            print("İşlem sayısı: \(allTransactions.count)") // Hata ayıklama çıktısı
            
            // İşlem yoksa uyarı göster
            guard !allTransactions.isEmpty else {
                await MainActor.run {
                    exportData = "No transactions found"
                    showingExportSheet = true
                }
                return
            }
            
            // CSV başlıkları
            let headers = [
                "Date",
                "Title",
                "Amount",
                "Currency",
                "Type",
                "Category",
                "Notes",
                "Is Recurring",
                "Recurring Type",
                "Recurring Duration",
                "Recurring End Date"
            ]
            
            // CSV metnini oluştur
            var csvText = headers.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
            
            // Tarih biçimlendirici
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            
            // Her işlem için CSV satırı oluştur
            for transaction in allTransactions {
                print("İşlem işleniyor: \(transaction.title)") // Hata ayıklama çıktısı
                
                let amount = String(format: "%.2f", abs(transaction.amount))
                
                let row = [
                    dateFormatter.string(from: transaction.date),
                    transaction.title,
                    amount,
                    defaultCurrency,
                    transaction.type.rawValue,
                    transaction.category,
                    transaction.notes ?? "",
                    transaction.isRecurring ? "Yes" : "No",
                    transaction.recurringType.rawValue,
                    transaction.recurringDuration?.description ?? "",
                    transaction.recurringEndDate.map { dateFormatter.string(from: $0) } ?? ""
                ].map { value in
                    let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
                    return "\"\(escaped)\""
                }.joined(separator: ",")
                
                csvText += row + "\n"
            }
            
            // Geçici bir dosya oluştur (benzersiz bir isimle)
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "GelirGider_Export_\(timestamp).csv"
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
            
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            
            await MainActor.run {
                self.exportURL = fileURL
                self.showingExportSheet = true
            }
            
        } catch {
            print("❌ Export error: \(error.localizedDescription)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func clearAllData() {
        for transaction in transactions {
            modelContext.delete(transaction)
        }
    }
    
    private func requestNotificationPermission() {
        isProcessingNotifications = true
        Task {
            do {
                try await notificationManager.requestAuthorization()
            } catch {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
            isProcessingNotifications = false
        }
    }
    
    private func disableNotifications() {
        isProcessingNotifications = true
        Task {
            await notificationManager.disableNotifications()
            isProcessingNotifications = false
        }
    }
    
    private func sendTestNotification() {
        guard !isProcessingNotifications else { return }
        isProcessingNotifications = true
        
        Task {
            do {
                try await notificationManager.sendTestNotification()
            } catch {
                print("❌ Test notification error: \(error.localizedDescription)")
            }
            isProcessingNotifications = false
        }
    }
}

struct SettingIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 20))
            .foregroundColor(color)
            .frame(width: 30, alignment: .center)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            // Clean up temporary files after sharing
            if let fileURL = activityItems.first as? URL {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 