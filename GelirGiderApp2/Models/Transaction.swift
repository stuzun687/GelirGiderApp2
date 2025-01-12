import Foundation
import SwiftData

enum TransactionType: String, Codable {
    case income = "income"
    case expense = "expense"
}

enum RecurringType: String, Codable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var durationUnit: Calendar.Component {
        switch self {
        case .none: return .day
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
}

@Model
final class Transaction {
    @Attribute(.unique) let id: String
    var title: String
    var amount: Double
    var date: Date
    var type: TransactionType
    var category: String
    var notes: String?
    
    // Recurring transaction properties
    var isRecurring: Bool
    var recurringType: RecurringType
    var recurringDuration: Int? // Number of days/weeks/months/years
    var recurringEndDate: Date? // Computed based on duration
    var parentTransaction: Transaction?
    
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
        self.id = UUID().uuidString
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
    
    // Calculate end date based on duration
    func calculateEndDate() -> Date? {
        guard isRecurring,
              let duration = recurringDuration,
              duration > 0 else {
            return nil
        }
        
        return Calendar.current.date(
            byAdding: recurringType.durationUnit,
            value: duration,
            to: date
        )
    }
}

extension TransactionType {
    var description: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        }
    }
}

extension RecurringType {
    var description: String {
        switch self {
        case .none: return "None"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    var durationDescription: String {
        switch self {
        case .none: return "days"
        case .daily: return "days"
        case .weekly: return "weeks"
        case .monthly: return "months"
        case .yearly: return "years"
        }
    }
} 