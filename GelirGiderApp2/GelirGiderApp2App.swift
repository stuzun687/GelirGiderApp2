// Bu dosya, uygulamanın ana giriş noktasını ve temel yapılandırmasını içerir
// Gerekli kütüphaneleri içe aktarıyoruz
import SwiftUI
import SwiftData
import UserNotifications

// Ana uygulama yapısı - @main ile uygulamanın başlangıç noktası olarak işaretlendi
@main
struct GelirGiderApp2App: App {
    // UIApplicationDelegate protokolünü uygulayan sınıfı bağla
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    // SwiftData veritabanı için paylaşılan model konteyneri
    var sharedModelContainer: ModelContainer = {
        // Veritabanı şemasını tanımla - Transaction modelini içerir
        let schema = Schema([
            Transaction.self,
        ])
        // Model yapılandırmasını oluştur (bellekte tutulmayacak şekilde)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            // Model konteynerini oluştur ve döndür
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Konteyner oluşturulamazsa uygulamayı sonlandır
            fatalError("Model Konteyneri oluşturulamadı: \(error)")
        }
    }()

    // Uygulama görünüm yapısı
    var body: some Scene {
        WindowGroup {
            // Ana içerik görünümünü başlat
            ContentView()
        }
        // Veritabanı konteynerini tüm görünümlere sağla
        .modelContainer(sharedModelContainer)
    }
}

// Uygulama delegesi sınıfı - Bildirim yönetimi için gerekli
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // Uygulama başlatıldığında çağrılan fonksiyon
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Bildirim delegesini ayarla
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Uygulama ön plandayken bildirim geldiğinde çağrılan fonksiyon
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Uygulama ön plandayken bile banner göster ve ses çal
        return [.banner, .sound, .badge]
    }
    
    // Bildirime tıklandığında çağrılan fonksiyon
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("📱 Bildirime tıklandı: \(response.notification.request.identifier)")
    }
}
