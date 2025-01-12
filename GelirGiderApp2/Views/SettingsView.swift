import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultCurrency") private var defaultCurrency = "₺"
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingExportSheet = false
    @State private var showingClearDataAlert = false
    @State private var exportData: String = ""
    @State private var isProcessingNotifications = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            List {
                // App Preferences
                Section {
                    // Currency Picker
                    HStack {
                        SettingIcon(icon: "dollarsign.circle.fill", color: .blue)
                        Picker("Currency", selection: $defaultCurrency) {
                            Text("₺ (TRY)").tag("₺")
                            Text("$ (USD)").tag("$")
                            Text("€ (EUR)").tag("€")
                        }
                    }
                    
                    // Theme Toggle
                    HStack {
                        SettingIcon(icon: "moon.circle.fill", color: .purple)
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }
                    
                    // Notifications Toggle
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
                                        requestNotificationPermission()
                                    } else {
                                        disableNotifications()
                                    }
                                }
                            ))
                        }
                    }
                    
                    if notificationManager.isNotificationsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications are enabled")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            // Test notification button
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
                
                // Data Management
                Section {
                    // Export Data
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
                    
                    // Clear Data
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
                
                // About Section
                Section {
                    // Version Info
                    HStack {
                        SettingIcon(icon: "info.circle.fill", color: .blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    // Rate App
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
                    
                    // Privacy Policy
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
                    
                    // Terms of Service
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
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("Are you sure you want to clear all data? This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                        .navigationTitle("Export Data")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    private func prepareExport() async {
        do {
            // Create a descriptor to fetch all transactions
            let descriptor = FetchDescriptor<Transaction>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            // Fetch all transactions using the model context
            let allTransactions = try modelContext.fetch(descriptor)
            
            print("Number of transactions: \(allTransactions.count)") // Debug print
            
            guard !allTransactions.isEmpty else {
                await MainActor.run {
                    exportData = "No transactions found"
                    showingExportSheet = true
                }
                return
            }
            
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
            
            var csvText = headers.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            
            for transaction in allTransactions {
                print("Processing transaction: \(transaction.title)") // Debug print
                
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
            
            // Create a temporary file with a unique name
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