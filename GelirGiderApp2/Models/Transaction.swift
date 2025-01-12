// Bu dosya, uygulamamızdaki gelir ve gider işlemlerini temsil eden veri modelini içerir.
// Gerekli kütüphaneleri içe aktarıyoruz
import Foundation
import SwiftData

// İşlem tipini belirten enum (gelir veya gider)
// Bu enum, her işlemin gelir mi yoksa gider mi olduğunu belirtir
enum TransactionType: String, Codable {
    case income = "income"    // Gelir işlemi
    case expense = "expense"  // Gider işlemi
}

// Tekrarlanan işlemlerin türünü belirten enum
// Bu enum, bir işlemin hangi sıklıkla tekrarlanacağını belirtir
enum RecurringType: String, Codable {
    case none = "none"       // Tekrarlanmayan işlem
    case daily = "daily"     // Günlük tekrarlanan işlem
    case weekly = "weekly"   // Haftalık tekrarlanan işlem
    case monthly = "monthly" // Aylık tekrarlanan işlem
    case yearly = "yearly"   // Yıllık tekrarlanan işlem
    
    // Tekrarlama süresinin birimini belirten hesaplama özelliği
    // Her tekrarlama türü için uygun zaman birimini döndürür
    var durationUnit: Calendar.Component {
        switch self {
        case .none: return .day      // Tekrarlanmayan için gün
        case .daily: return .day     // Günlük için gün
        case .weekly: return .weekOfYear  // Haftalık için hafta
        case .monthly: return .month  // Aylık için ay
        case .yearly: return .year   // Yıllık için yıl
        }
    }
}

// Ana işlem sınıfı - Her bir gelir veya gider işlemini temsil eder
@Model  // SwiftData ile veritabanı entegrasyonu için gerekli
final class Transaction {
    @Attribute(.unique) let id: String  // Her işlem için benzersiz kimlik
    var title: String      // İşlem başlığı (örn: "Market Alışverişi")
    var amount: Double     // İşlem tutarı (örn: 100.50)
    var date: Date        // İşlem tarihi
    var type: TransactionType  // İşlem tipi (gelir/gider)
    var category: String   // İşlem kategorisi (örn: "Yiyecek", "Kira")
    var notes: String?     // İşlem için opsiyonel notlar
    
    // Tekrarlanan işlemler için özellikler
    var isRecurring: Bool  // İşlemin tekrarlı olup olmadığı
    var recurringType: RecurringType  // Tekrarlanma türü
    var recurringDuration: Int?  // Tekrarlanma süresi (kaç gün/hafta/ay/yıl)
    var recurringEndDate: Date?  // Tekrarlanmanın biteceği tarih
    var parentTransaction: Transaction?  // Ana işlem referansı (tekrarlanan işlemler için)
    
    // Yeni bir işlem oluşturmak için kullanılan başlatıcı (constructor)
    init(
        title: String,
        amount: Double,
        date: Date,
        type: TransactionType,
        category: String,
        notes: String? = nil,
        isRecurring: Bool = false,
        recurringType: RecurringType = .none,
        recurringDuration: Int? = nil,
        recurringEndDate: Date? = nil,
        parentTransaction: Transaction? = nil
    ) {
        self.id = UUID().uuidString  // Benzersiz bir ID oluştur
        self.title = title
        self.amount = amount
        self.date = date
        self.type = type
        self.category = category
        self.notes = notes
        self.isRecurring = isRecurring
        self.recurringType = recurringType
        self.recurringDuration = recurringDuration
        self.recurringEndDate = recurringEndDate
        self.parentTransaction = parentTransaction
    }
    
    // Tekrarlanan işlemin bitiş tarihini hesaplayan fonksiyon
    func calculateEndDate() -> Date? {
        // Eğer işlem tekrarlı değilse veya geçerli bir süre yoksa nil döndür
        guard isRecurring,
              let duration = recurringDuration,
              duration > 0 else {
            return nil
        }
        
        // Başlangıç tarihine tekrarlama süresini ekleyerek bitiş tarihini hesapla
        return Calendar.current.date(
            byAdding: recurringType.durationUnit,
            value: duration,
            to: date
        )
    }
}

// İşlem tipinin kullanıcı dostu açıklamasını sağlayan uzantı
extension TransactionType {
    var description: String {
        switch self {
        case .income: return "Income"   // Gelir
        case .expense: return "Expense" // Gider
        }
    }
}

// Tekrarlama tipinin kullanıcı dostu açıklamalarını sağlayan uzantı
extension RecurringType {
    // Tekrarlama türünün açıklaması
    var description: String {
        switch self {
        case .none: return "None"     // Tekrarlanmayan
        case .daily: return "Daily"    // Günlük
        case .weekly: return "Weekly"  // Haftalık
        case .monthly: return "Monthly" // Aylık
        case .yearly: return "Yearly"  // Yıllık
        }
    }
    
    // Tekrarlama süresinin birim açıklaması
    var durationDescription: String {
        switch self {
        case .none: return "days"    // Gün
        case .daily: return "days"   // Gün
        case .weekly: return "weeks" // Hafta
        case .monthly: return "months" // Ay
        case .yearly: return "years"  // Yıl
        }
    }
}