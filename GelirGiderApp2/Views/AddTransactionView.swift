import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Basic transaction states
    @State private var title = ""
    @State private var amount = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategory = ""
    @State private var date = Date()
    @State private var notes = ""
    
    // UI states
    @State private var showingCategoryPicker = false
    @State private var isRecurring = false
    @State private var recurringType: RecurringType = .monthly
    @State private var recurringDuration: Int = 1
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showNotificationAlert = false
    @State private var notificationError: Error?
    @State private var showSuccessMessage = false
    @State private var isNotificationAuthorized = false
    @State private var enableNotification = true
    
    private var isFormValid: Bool {
        !title.isEmpty && !amount.isEmpty && !selectedCategory.isEmpty
    }
    
    private var notificationPreviewText: String {
        guard enableNotification else { return "Notifications disabled for this transaction" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var text = "You will be notified on \(formatter.string(from: date))"
        
        if isRecurring {
            text += "\nRecurring: "
            switch recurringType {
            case .daily:
                text += "Daily"
            case .weekly:
                text += "Every week"
            case .monthly:
                text += "Every month"
            case .yearly:
                text += "Every year"
            case .none:
                break
            }
            
            if let endDate = calculateEndDate() {
                text += " until \(formatter.string(from: endDate))"
            }
        }
        
        return text
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        amountCard
                        detailsCard
                        notificationSection
                    }
                    .padding(.vertical)
                }
                
                // Success Message
                if showSuccessMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Transaction saved successfully!")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6).opacity(0.95))
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .padding(.bottom, 32)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                showSuccessMessage = false
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveTransaction) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(isFormValid ? .accentColor : .gray)
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
            .alert("Notification Error", isPresented: $showNotificationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = notificationError {
                    Text("Error setting up notification: \(error.localizedDescription)\nPlease check your notification permissions in Settings.")
                } else {
                    Text("There was an error setting up the notification. Please check your notification permissions in Settings.")
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var amountCard: some View {
        VStack(spacing: 20) {
            // Type Selector
            HStack(spacing: 24) {
                ForEach([TransactionType.expense, .income], id: \.self) { transactionType in
                    Button(action: { withAnimation { type = transactionType } }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(type == transactionType ?
                                        (transactionType == .expense ? Color.red : Color.green) :
                                        Color(.systemGray5))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: transactionType == .expense ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(type == transactionType ? .white : transactionType == .expense ? .red : .green)
                            }
                            
                            Text(transactionType == .expense ? "Expense" : "Income")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(type == transactionType ? (transactionType == .expense ? .red : .green) : .gray)
                        }
                    }
                }
            }
            
            // Amount Input
            HStack(alignment: .firstTextBaseline) {
                Text("₺")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(type == .expense ? .red : .green)
                
                TextField("0.00", text: $amount)
                    .font(.system(size: 40, weight: .medium))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(type == .expense ? .red : .green)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            TransactionCard(colorScheme: colorScheme)
        )
        .padding(.horizontal)
    }
    
    private var detailsCard: some View {
        VStack(spacing: 24) {
            // Title & Category Section
            VStack(spacing: 16) {
                titleField
                categoryButton
            }
            
            // Date Section
            dateButton
            
            // Recurring Section
            recurringSection
            
            // Notes Section
            notesField
        }
        .padding(24)
        .background(
            TransactionCard(colorScheme: colorScheme)
        )
        .padding(.horizontal)
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Title", systemImage: "text.alignleft")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("Enter title", text: $title)
                .textFieldStyle(.plain)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    private var categoryButton: some View {
        Button(action: { showingCategoryPicker = true }) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Category", systemImage: "folder")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    if !selectedCategory.isEmpty {
                        Label(selectedCategory, systemImage: getCategoryIcon(selectedCategory))
                            .foregroundColor(type == .expense ? .red : .green)
                    } else {
                        Text("Select Category")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
    
    private var dateButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Date & Time", systemImage: "calendar")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button(action: { withAnimation { showDatePicker.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDatePreview(date))
                            .foregroundColor(.primary)
                        Text(formatTime(date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(showDatePicker ? 90 : 0))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            
            if showDatePicker {
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recurring Toggle with Preview
            Button(action: { withAnimation { isRecurring.toggle() } }) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(isRecurring ? Color.blue.opacity(0.1) : Color(.systemGray5))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: isRecurring ? "repeat.circle.fill" : "repeat.circle")
                            .font(.title2)
                            .foregroundColor(isRecurring ? .accentColor : .gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Recurring Transaction")
                                .font(.headline)
                            
                            if isRecurring {
                                Text("ON")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.accentColor))
                            }
                        }
                        
                        if isRecurring {
                            Text("Repeats \(recurringType.description.lowercased()) for \(recurringDuration) " + (recurringDuration == 1 ? String(recurringType.durationDescription.dropLast()) : recurringType.durationDescription))
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("One-time transaction")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isRecurring ? "chevron.up" : "chevron.right")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isRecurring ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )
            }
            
            if isRecurring {
                VStack(spacing: 20) {
                    // Frequency Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("How often?", systemImage: "clock")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach([RecurringType.daily, .weekly, .monthly, .yearly], id: \.self) { type in
                                Button(action: { withAnimation { recurringType = type } }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: getRecurringTypeIcon(type))
                                            .font(.title2)
                                        Text(type.description)
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(recurringType == type ? Color.accentColor : Color(.systemGray5))
                                    )
                                    .foregroundColor(recurringType == type ? .white : .primary)
                                }
                            }
                        }
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 12) {
                        Label("For how long?", systemImage: "calendar.badge.clock")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            // Duration Stepper
                            HStack(spacing: 16) {
                                Button(action: { if recurringDuration > 1 { recurringDuration -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(recurringDuration > 1 ? .accentColor : .gray)
                                }
                                
                                Text("\(recurringDuration)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 30)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: { recurringDuration += 1 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            
                            Text(recurringDuration == 1 ? String(recurringType.durationDescription.dropLast()) : recurringType.durationDescription)
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        
                        // End date preview
                        if let endDate = calculateEndDate() {
                            HStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundColor(.orange)
                                Text("Ends on " + formatDate(endDate))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
    
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("Add notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Notifications", systemImage: "bell.badge")
                .font(.headline)
                .foregroundColor(.gray)
            
            Toggle(isOn: $enableNotification) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Notifications")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Get reminded about this transaction")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .tint(.blue)
            
            if enableNotification {
                Text(notificationPreviewText)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
        }
        .padding(24)
        .background(
            TransactionCard(colorScheme: colorScheme)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func formatDatePreview(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func getCategoryIcon(_ category: String) -> String {
        let icons = [
            "Food": "fork.knife",
            "Transportation": "car.fill",
            "Shopping": "cart.fill",
            "Bills": "doc.text.fill",
            "Entertainment": "tv.fill",
            "Salary": "dollarsign.circle.fill",
            "Investment": "chart.line.uptrend.xyaxis",
            "Other": "creditcard.fill"
        ]
        return icons[category] ?? "creditcard.fill"
    }
    
    private func calculateEndDate() -> Date? {
        guard isRecurring, recurringDuration > 0 else { return nil }
        return Calendar.current.date(
            byAdding: recurringType.durationUnit,
            value: recurringDuration,
            to: date
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let endDate = isRecurring ? calculateEndDate() : nil
        
        // Create main transaction
        let mainTransaction = Transaction(
            title: title,
            amount: amountValue,
            date: date,
            type: type,
            category: selectedCategory,
            notes: notes.isEmpty ? nil : notes,
            isRecurring: isRecurring,
            recurringType: recurringType,
            recurringDuration: isRecurring ? recurringDuration : nil,
            recurringEndDate: endDate
        )
        
        modelContext.insert(mainTransaction)
        
        // Schedule notification only if enabled for this transaction
        if enableNotification {
            Task {
                do {
                    try await NotificationManager.shared.scheduleTransactionNotification(for: mainTransaction)
                } catch NotificationManager.NotificationError.notificationsDenied {
                    print("❌ Notifications are denied")
                    DispatchQueue.main.async {
                        notificationError = NotificationManager.NotificationError.notificationsDenied
                        showNotificationAlert = true
                    }
                } catch {
                    print("❌ Failed to schedule notification: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        notificationError = error
                        showNotificationAlert = true
                    }
                }
            }
        }
        
        // Create recurring transactions only if duration > 1
        if isRecurring && recurringDuration > 1, let endDate = endDate {
            var currentDate = date
            
            while currentDate <= endDate {
                guard let nextDate = Calendar.current.date(
                    byAdding: recurringType.durationUnit,
                    value: 1,
                    to: currentDate
                ) else { break }
                
                if nextDate > endDate { break }
                
                let recurringTransaction = Transaction(
                    title: title,
                    amount: amountValue,
                    date: nextDate,
                    type: type,
                    category: selectedCategory,
                    notes: notes.isEmpty ? nil : notes,
                    isRecurring: false,
                    recurringType: .none,
                    parentTransaction: mainTransaction
                )
                
                modelContext.insert(recurringTransaction)
                currentDate = nextDate
            }
        }
        
        // Show success message and dismiss
        withAnimation(.easeInOut(duration: 0.3)) {
            showSuccessMessage = true
        }
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    private func getRecurringTypeIcon(_ type: RecurringType) -> String {
        switch type {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly: return "calendar.circle.fill"
        case .none: return "calendar"
        }
    }
}



struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: String
    
    let categories = [
        "Food": "fork.knife",
        "Transportation": "car.fill",
        "Shopping": "cart.fill",
        "Bills": "doc.text.fill",
        "Entertainment": "tv.fill",
        "Salary": "dollarsign.circle.fill",
        "Investment": "chart.line.uptrend.xyaxis",
        "Other": "creditcard.fill"
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(categories.keys.sorted()), id: \.self) { category in
                    Button {
                        selectedCategory = category
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: categories[category] ?? "creditcard.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            Text(category)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
