// Bu dosya, uygulamamızdaki bildirim sistemini yöneten sınıfı içerir
// Bildirimler için gerekli kütüphaneleri içe aktarıyoruz
import Foundation
import UserNotifications
import UIKit

// Ana iş parçacığında çalışacak şekilde işaretlendi
@MainActor
// Bildirim yöneticisi sınıfı - Tüm bildirim işlemlerini yönetir
class NotificationManager: ObservableObject {
    // Singleton örnek - tüm uygulama için tek bir bildirim yöneticisi
    static let shared = NotificationManager()
    
    // Bildirimlerin durumunu takip eden değişkenler
    @Published var isNotificationsEnabled: Bool = false  // Bildirimlerin aktif olup olmadığı
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined  // Bildirim izin durumu
    
    // Özel başlatıcı - singleton pattern için
    private init() {
        Task {
            await updateAuthorizationStatus()  // Başlangıçta bildirim durumunu kontrol et
        }
    }
    
    // Bildirim izin durumunu güncelleyen fonksiyon
    private func updateAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        self.isNotificationsEnabled = settings.authorizationStatus == .authorized
        
        // Mevcut bildirim ayarlarını konsola yazdır (geliştirici için)
        print("📱 Mevcut bildirim ayarları:")
        print("- Yetkilendirme durumu: \(settings.authorizationStatus.rawValue)")
        print("- Uyarı ayarı: \(settings.alertSetting.rawValue)")
        print("- Ses ayarı: \(settings.soundSetting.rawValue)")
        print("- Rozet ayarı: \(settings.badgeSetting.rawValue)")
    }
    
    // Bildirim izni isteyen fonksiyon
    func requestAuthorization() async throws {
        print("🔐 Bildirim izni isteniyor...")
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        
        // Eğer izin durumu zaten belirlenmişse, ayarları kontrol et
        guard settings.authorizationStatus == .notDetermined else {
            if settings.authorizationStatus == .denied {
                print("⚠️ Bildirimler reddedildi. Lütfen Ayarlar'dan etkinleştirin.")
                throw NotificationError.notificationsDenied
            }
            return
        }
        
        // Bildirim iznini iste
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        await updateAuthorizationStatus()
        
        print("🔐 Yetkilendirme \(granted ? "verildi" : "reddedildi")")
    }
    
    // Test bildirimi gönderen fonksiyon
    func sendTestNotification() async throws {
        print("🔔 Test bildirimi hazırlanıyor...")
        
        // İzin durumunu kontrol et
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("⚠️ Bildirimler için yetki yok")
            throw NotificationError.notificationsDenied
        }
        
        // Bildirim içeriğini oluştur
        let content = UNMutableNotificationContent()
        content.title = "Test Bildirimi"
        content.body = "Eğer bunu görüyorsanız, bildirimler çalışıyor! 🎉"
        content.sound = .default
        content.badge = 1
        
        // Tetikleyici oluştur (5 saniye sonrası için)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Benzersiz kimlikle bildirim isteği oluştur
        let identifier = "test-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Bildirimi planla
        print("🚀 Test bildirimi planlanıyor...")
        try await UNUserNotificationCenter.current().add(request)
        print("✅ Test bildirimi başarıyla planlandı")
        
        // Bekleyen bildirimleri listele (geliştirici için)
        let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 Bekleyen bildirimler: \(pendingNotifications.count)")
        for notification in pendingNotifications {
            print("- \(notification.identifier)")
        }
    }
    
    // İşlem için bildirim planlayan fonksiyon
    func scheduleTransactionNotification(for transaction: Transaction) async throws {
        print("🔔 İşlem bildirimi hazırlanıyor...")
        
        // İzin durumunu kontrol et
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("⚠️ Bildirimler için yetki yok")
            throw NotificationError.notificationsDenied
        }
        
        // Bildirim içeriğini oluştur
        let content = UNMutableNotificationContent()
        content.title = transaction.type == .income ? "Gelir Hatırlatıcısı" : "Gider Hatırlatıcısı"
        content.body = "\(transaction.title): \(String(format: "%.2f", transaction.amount)) ₺"
        content.sound = .default
        content.badge = 1
        
        // Tetikleyici için tarih bileşenlerini oluştur
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        print("📅 Bildirim planlanıyor: \(formatDebugDate(transaction.date))")
        
        // Tarih bileşenlerini oluştur
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: transaction.date)
        components.second = 0  // Saniyeyi sıfırla
        components.timeZone = TimeZone.current
        
        // Tetikleyici oluştur
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Benzersiz kimlikle bildirim isteği oluştur
        let identifier = "transaction-\(transaction.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Bildirimi planla
        try await UNUserNotificationCenter.current().add(request)
        print("✅ İşlem bildirimi planlandı: \(formatDebugDate(transaction.date))")
        
        // Eğer tekrarlanan bir işlemse, gelecek bildirimleri planla
        if transaction.isRecurring, let endDate = transaction.recurringEndDate {
            try await scheduleRecurringNotifications(for: transaction, until: endDate)
        }
        
        // Planlanan bildirimleri kontrol et
        await verifyScheduledNotifications()
    }
    
    // Tekrarlanan bildirimler için yardımcı fonksiyon
    private func scheduleRecurringNotifications(for transaction: Transaction, until endDate: Date) async throws {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        var currentDate = transaction.date
        
        print("🔄 Tekrarlanan bildirimler planlanıyor (bitiş: \(formatDebugDate(endDate)))")
        
        while currentDate <= endDate {
            guard let nextDate = calendar.date(
                byAdding: transaction.recurringType.durationUnit,
                value: 1,
                to: currentDate
            ) else { break }
            
            if nextDate > endDate { break }
            
            // Tekrarlanan bildirim için içerik oluştur
            let content = UNMutableNotificationContent()
            content.title = transaction.type == .income ? "Tekrarlanan Gelir" : "Tekrarlanan Gider"
            content.body = "\(transaction.title): \(String(format: "%.2f", transaction.amount)) ₺"
            content.sound = .default
            
            // Tarih bileşenlerini oluştur
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
            components.second = 0
            components.timeZone = TimeZone.current
            
            // Tetikleyici oluştur
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // Benzersiz kimlikle bildirim isteği oluştur
            let identifier = "transaction-\(transaction.id)-\(Int(nextDate.timeIntervalSince1970))"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Bildirimi planla
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Tekrarlanan bildirim planlandı: \(formatDebugDate(nextDate))")
            
            currentDate = nextDate
        }
    }
    
    // Tarih biçimlendirme yardımcı fonksiyonu
    private func formatDebugDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    // Planlanan bildirimleri kontrol eden yardımcı fonksiyon
    private func verifyScheduledNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📬 Mevcut bekleyen bildirimler: \(requests.count)")
        for request in requests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                print("🔔 Bildirim ID: \(request.identifier)")
                print("📅 Sonraki tetikleme: \(formatDebugDate(nextTriggerDate))")
                print("📝 İçerik: \(request.content.title) - \(request.content.body)")
            }
        }
    }
    
    // Bildirimleri devre dışı bırakan fonksiyon
    func disableNotifications() async {
        print("🔕 Bildirimler devre dışı bırakılıyor...")
        
        do {
            // Tüm bekleyen bildirimleri kaldır
            await UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            print("🗑 Tüm bekleyen bildirimler kaldırıldı")
            
            // Yerel durumu güncelle
            self.isNotificationsEnabled = false
            self.authorizationStatus = .denied
            
            // Bildirim rozetini kaldır
            await UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            try await UNUserNotificationCenter.current().setBadgeCount(0)
            
            print("✅ Bildirimler devre dışı bırakıldı")
        } catch {
            print("❌ Bildirimler devre dışı bırakılırken hata: \(error.localizedDescription)")
        }
        
        print("ℹ️ Bildirimleri tamamen devre dışı bırakmak için lütfen Ayarlar uygulamasını kullanın")
    }
    
    // Bildirim hataları için enum
    enum NotificationError: LocalizedError {
        case notificationsDenied  // Bildirimler reddedildiğinde
        
        var errorDescription: String? {
            switch self {
            case .notificationsDenied:
                return "Bildirimler devre dışı. Lütfen Ayarlar'dan etkinleştirin."
            }
        }
    }
}
