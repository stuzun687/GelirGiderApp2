import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    private func updateAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        self.isNotificationsEnabled = settings.authorizationStatus == .authorized
        
        print("📱 Current notification settings:")
        print("- Authorization status: \(settings.authorizationStatus.rawValue)")
        print("- Alert setting: \(settings.alertSetting.rawValue)")
        print("- Sound setting: \(settings.soundSetting.rawValue)")
        print("- Badge setting: \(settings.badgeSetting.rawValue)")
    }
    
    func requestAuthorization() async throws {
        print("🔐 Requesting notification authorization...")
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        
        // If already determined, check if we need to open settings
        guard settings.authorizationStatus == .notDetermined else {
            if settings.authorizationStatus == .denied {
                print("⚠️ Notifications are denied. Please enable in Settings.")
                throw NotificationError.notificationsDenied
            }
            return
        }
        
        // Request authorization
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        await updateAuthorizationStatus()
        
        print("🔐 Authorization \(granted ? "granted" : "denied")")
    }
    
    func sendTestNotification() async throws {
        print("🔔 Preparing test notification...")
        
        // Check authorization
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("⚠️ Notifications are not authorized")
            throw NotificationError.notificationsDenied
        }
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "If you see this, notifications are working! 🎉"
        content.sound = .default
        content.badge = 1
        
        // Create trigger (5 seconds from now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Create request with unique identifier
        let identifier = "test-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        print("🚀 Scheduling test notification...")
        try await UNUserNotificationCenter.current().add(request)
        print("✅ Test notification scheduled successfully")
        
        // Debug: List pending notifications
        let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 Pending notifications: \(pendingNotifications.count)")
        for notification in pendingNotifications {
            print("- \(notification.identifier)")
        }
    }
    
    func scheduleTransactionNotification(for transaction: Transaction) async throws {
        print("🔔 Preparing transaction notification...")
        
        // Check authorization
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("⚠️ Notifications are not authorized")
            throw NotificationError.notificationsDenied
        }
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = transaction.type == .income ? "Income Reminder" : "Expense Reminder"
        content.body = "\(transaction.title): \(String(format: "%.2f", transaction.amount)) ₺"
        content.sound = .default
        content.badge = 1
        
        // Create date components for the trigger
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        print("📅 Scheduling notification for: \(formatDebugDate(transaction.date))")
        
        // Create date components
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: transaction.date)
        components.second = 0 // Ensure seconds are zero
        components.timeZone = TimeZone.current
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request with unique identifier
        let identifier = "transaction-\(transaction.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        try await UNUserNotificationCenter.current().add(request)
        print("✅ Transaction notification scheduled for: \(formatDebugDate(transaction.date))")
        
        // If recurring, schedule future notifications
        if transaction.isRecurring, let endDate = transaction.recurringEndDate {
            try await scheduleRecurringNotifications(for: transaction, until: endDate)
        }
        
        // Debug: List all pending notifications
        await verifyScheduledNotifications()
    }
    
    private func scheduleRecurringNotifications(for transaction: Transaction, until endDate: Date) async throws {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        var currentDate = transaction.date
        
        print("🔄 Scheduling recurring notifications until: \(formatDebugDate(endDate))")
        
        while currentDate <= endDate {
            guard let nextDate = calendar.date(
                byAdding: transaction.recurringType.durationUnit,
                value: 1,
                to: currentDate
            ) else { break }
            
            if nextDate > endDate { break }
            
            // Create content for recurring notification
            let content = UNMutableNotificationContent()
            content.title = transaction.type == .income ? "Recurring Income" : "Recurring Expense"
            content.body = "\(transaction.title): \(String(format: "%.2f", transaction.amount)) ₺"
            content.sound = .default
            
            // Create date components
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
            components.second = 0
            components.timeZone = TimeZone.current
            
            // Create trigger
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // Create request with unique identifier
            let identifier = "transaction-\(transaction.id)-\(Int(nextDate.timeIntervalSince1970))"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Schedule notification
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Recurring notification scheduled for: \(formatDebugDate(nextDate))")
            
            currentDate = nextDate
        }
    }
    
    private func formatDebugDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func verifyScheduledNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📬 Current pending notifications: \(requests.count)")
        for request in requests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                print("🔔 Notification ID: \(request.identifier)")
                print("📅 Next trigger: \(formatDebugDate(nextTriggerDate))")
                print("📝 Content: \(request.content.title) - \(request.content.body)")
            }
        }
    }
    
    func disableNotifications() async {
        print("🔕 Disabling notifications...")
        
        do {
            // Remove all pending notifications
            await UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            print("🗑 Removed all pending notifications")
            
            // Update local state
            self.isNotificationsEnabled = false
            self.authorizationStatus = .denied
            
            // Remove notification badge
            await UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            try await UNUserNotificationCenter.current().setBadgeCount(0)
            
            print("✅ Notifications disabled")
        } catch {
            print("❌ Error while disabling notifications: \(error.localizedDescription)")
        }
        
        print("ℹ️ To completely disable notifications, please use the Settings app")
    }
    
    enum NotificationError: LocalizedError {
        case notificationsDenied
        
        var errorDescription: String? {
            switch self {
            case .notificationsDenied:
                return "Notifications are disabled. Please enable them in Settings."
            }
        }
    }
}
