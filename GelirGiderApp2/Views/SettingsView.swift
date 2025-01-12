import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Query private var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultCurrency") private var defaultCurrency = "₺"
    @AppStorage("useBiometrics") private var useBiometrics = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var showingExportSheet = false
    @State private var showingClearDataAlert = false
    @State private var exportData: String = ""
    
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
                        Toggle("Dark Mode", isOn: .constant(false))
                            .disabled(true)
                    }
                    
                    // Biometrics Toggle
                    HStack {
                        SettingIcon(icon: "faceid", color: .green)
                        Toggle("Use Face ID", isOn: $useBiometrics)
                    }
                    
                    // Notifications Toggle
                    HStack {
                        SettingIcon(icon: "bell.circle.fill", color: .red)
                        Toggle("Notifications", isOn: $notificationsEnabled)
                    }
                } header: {
                    Text("App Preferences")
                }
                
                // Data Management
                Section {
                    // Export Data
                    Button(action: prepareExport) {
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
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("Are you sure you want to clear all data? This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                NavigationView {
                    ShareSheet(activityItems: [exportData])
                        .navigationTitle("Export Data")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    private func prepareExport() {
        var csvText = "Date,Title,Amount,Type,Category,Notes\n"
        
        for transaction in transactions {
            let row = [
                formatDate(transaction.date),
                transaction.title,
                String(format: "%.2f", transaction.amount),
                transaction.type.rawValue,
                transaction.category,
                transaction.notes ?? ""
            ].map { "\"\($0)\"" }.joined(separator: ",")
            
            csvText += row + "\n"
        }
        
        exportData = csvText
        showingExportSheet = true
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
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 