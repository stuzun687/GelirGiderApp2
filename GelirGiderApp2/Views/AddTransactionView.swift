// MARK: - Gerekli Framework'lerin Import Edilmesi
import SwiftUI // Kullanıcı arayüzü bileşenleri için
import SwiftData // Veri yönetimi ve kalıcı depolama için

// MARK: - Ana İşlem Ekleme Görünümü
/// Bu görünüm, yeni gelir veya gider işlemlerinin eklenmesini sağlar.
/// Kullanıcılar burada işlem detaylarını girebilir, tekrarlayan işlemler oluşturabilir
/// ve bildirim ayarlarını yapılandırabilirler.
struct AddTransactionView: View {
    // MARK: - Environment Değişkenleri
    @Environment(\.modelContext) private var modelContext // Veri kaydetme işlemleri için
    @Environment(\.dismiss) private var dismiss // Görünümü kapatmak için
    @Environment(\.colorScheme) private var colorScheme // Karanlık/Aydınlık mod kontrolü için
    
    // MARK: - Temel İşlem Durumları
    /// İşlemin temel bilgilerini tutan state değişkenleri
    @State private var title = "" // İşlem başlığı
    @State private var amount = "" // İşlem tutarı
    @State private var type: TransactionType = .expense // İşlem tipi (gelir/gider)
    @State private var selectedCategory = "" // Seçilen kategori
    @State private var date = Date() // İşlem tarihi
    @State private var notes = "" // İşlem notları
    
    // MARK: - Kullanıcı Arayüzü Durumları
    /// Arayüz etkileşimlerini kontrol eden state değişkenleri
    @State private var showingCategoryPicker = false // Kategori seçici görünümünün durumu
    @State private var isRecurring = false // Tekrarlayan işlem durumu
    @State private var recurringType: RecurringType = .monthly // Tekrarlama periyodu
    @State private var recurringDuration: Int = 1 // Tekrarlama süresi
    @State private var showDatePicker = false // Tarih seçici görünümünün durumu
    @State private var showTimePicker = false // Saat seçici görünümünün durumu
    @State private var showNotificationAlert = false // Bildirim hata uyarısının durumu
    @State private var notificationError: Error? // Bildirim hatası
    @State private var showSuccessMessage = false // Başarılı kayıt mesajının durumu
    @State private var isNotificationAuthorized = false // Bildirim izni durumu
    @State private var enableNotification = true // Bildirim aktiflik durumu
    
    // MARK: - Form Doğrulama
    /// Formun geçerli olup olmadığını kontrol eden hesaplanmış özellik
    private var isFormValid: Bool {
        !title.isEmpty && !amount.isEmpty && !selectedCategory.isEmpty
    }
    
    // MARK: - Bildirim Önizleme Metni
    /// Bildirim ayarlarının özet metnini oluşturan hesaplanmış özellik
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
    
    // MARK: - Ana Görünüm Yapısı
    /// Görünümün ana body yapısı
    /// Karanlık tema üzerine yerleştirilmiş scroll view içinde
    /// işlem detaylarının girileceği kartlar bulunur
    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Arka Plan Tasarımı
                /// Premium görünümlü siyah gradyan arka plan
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
                        amountCard // Tutar giriş kartı
                        detailsCard // Detay bilgileri kartı
                        notificationSection // Bildirim ayarları bölümü
                    }
                    .padding(.vertical)
                }
                
                // MARK: - Başarı Mesajı Gösterimi
                /// İşlem başarıyla kaydedildiğinde gösterilen geçici mesaj
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
    
    // MARK: - Görünüm Bileşenleri
    /// Her bir bileşen, kullanıcı arayüzünün belirli bir bölümünü oluşturur
    
    // MARK: - Tutar Kartı Bileşeni
    /// İşlem tipinin seçildiği ve tutarın girildiği kart görünümü
    private var amountCard: some View {
        VStack(spacing: 20) {
            // İşlem Tipi Seçici
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
            
            // Tutar Girişi
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
    
    // MARK: - Detay Kartı Bileşeni
    /// İşlem detaylarının girildiği kart görünümü
    private var detailsCard: some View {
        VStack(spacing: 24) {
            // Başlık ve Kategori Bölümü
            VStack(spacing: 16) {
                titleField
                categoryButton
            }
            
            // Tarih Bölümü
            dateButton
            
            // Tekrarlanan İşlem Bölümü
            recurringSection
            
            // Notlar Bölümü
            notesField
        }
        .padding(24)
        .background(
            TransactionCard(colorScheme: colorScheme)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Başlık Alanı
    /// İşlem başlığının girildiği metin alanı
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
    
    // MARK: - Kategori Seçim Butonu
    /// Kategori seçimini tetikleyen buton
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
    
    // MARK: - Tarih Seçim Butonu
    /// Tarih ve saat seçimini sağlayan buton ve tarih seçici
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
    
    // MARK: - Tekrarlanan İşlem Bölümü
    /// Tekrarlanan işlem ayarlarının yapılandırıldığı bölüm
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
    
    // MARK: - Not Alanı
    /// İşlem için not ekleme alanı
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
    
    // MARK: - Bildirim Bölümü
    /// Bildirim ayarlarının yapılandırıldığı bölüm
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
    
    // MARK: - Yardımcı Fonksiyonlar
    /// Görünümde kullanılan çeşitli yardımcı fonksiyonlar
    
    // MARK: - Tarih Formatı Fonksiyonu
    /// Tarihi kullanıcı dostu bir formatta gösterir
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
    
    // MARK: - Kategori İkon Fonksiyonu
    /// Her kategori için uygun sistem ikonunu döndürür
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
    
    // MARK: - Bitiş Tarihi Hesaplama Fonksiyonu
    /// Tekrarlayan işlemler için bitiş tarihini hesaplar
    private func calculateEndDate() -> Date? {
        guard isRecurring, recurringDuration > 0 else { return nil }
        return Calendar.current.date(
            byAdding: recurringType.durationUnit,
            value: recurringDuration,
            to: date
        )
    }
    
    // MARK: - Tarih Formatlama Fonksiyonları
    /// Tarihi ve saati formatlayan yardımcı fonksiyonlar
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
    
    // MARK: - İşlem Kaydetme Fonksiyonu
    /// Yeni işlemi veritabanına kaydeder ve gerekli bildirimleri ayarlar
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let endDate = isRecurring ? calculateEndDate() : nil
        
        // Ana işlemi oluştur
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
        
        // Bildirim ayarlarını yap
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
        
        // Tekrarlayan işlemleri oluştur
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
        
        // Başarı mesajını göster
        withAnimation(.easeInOut(duration: 0.3)) {
            showSuccessMessage = true
        }
        
        // Kısa bir gecikme ile görünümü kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    // MARK: - Tekrarlama Tipi İkon Fonksiyonu
    /// Her tekrarlama tipi için uygun sistem ikonunu döndürür
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



// MARK: - Kategori Seçici Görünümü
/// Kullanıcının işlem kategorisini seçmesini sağlayan alt görünüm
struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: String
    
    // Kategori ve ikonların eşleştirilmesi
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
