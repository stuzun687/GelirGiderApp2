# GelirGiderApp - Kişisel Finans Takip Uygulaması

## 👥 Geliştiriciler

- **Semih Tüzün 05210000930**
- **Elif Güngördü 05220000968**

## 📱 Proje Hakkında

GelirGiderApp, kişisel finans yönetimini kolaylaştırmak için tasarlanmış modern bir iOS uygulamasıdır. Kullanıcıların gelir ve giderlerini etkili bir şekilde takip etmelerini, bütçelerini yönetmelerini ve finansal hedeflerine ulaşmalarını sağlar.

## ✅ Proje Gereksinimleri ve Uygulama

### 📱 Çoklu Ekran Desteği
Uygulamamız 5'ten fazla ekran içermektedir:
1. **Dashboard (Ana Sayfa)**: Finansal durumun genel görünümü
2. **Transactions (İşlemler)**: Tüm gelir ve giderlerin listelendiği ekran
3. **Add Transaction (İşlem Ekleme)**: Yeni işlem ekleme formu
4. **Analytics (Analiz)**: Detaylı grafik ve istatistikler
5. **Settings (Ayarlar)**: Uygulama ayarları ve veri yönetimi
6. **Category Picker**: Kategori seçim ekranı

### 🔄 Ekran Yönlendirmesi
Uygulamamız, SwiftUI'nin otomatik düzen sistemi sayesinde ekran döndürmelerinden etkilenmez:
- Tüm görünümler adaptif tasarıma sahiptir
- `.navigationViewStyle(.stack)` kullanılarak tutarlı navigasyon sağlanır
- Dinamik boyutlandırma ve otomatik düzen ayarlamaları mevcuttur

### 📋 Liste Görünümleri (RecyclerView Eşdeğeri)
iOS'ta RecyclerView'in eşdeğeri olarak aşağıdaki yapıları kullanıyoruz:
- **LazyVStack**: Verimli bellek kullanımı için görünür öğeleri dinamik olarak yükler
- **List**: Kaydırılabilir, yeniden kullanılabilir hücreler sunar
- **ScrollView + ForEach**: Özelleştirilmiş kaydırılabilir listeler oluşturur

Örnekler:
- İşlemler listesi (`TransactionsView`)
- Kategori seçim listesi (`CategoryPickerView`)
- Dashboard'daki son işlemler listesi

### 📤 Harici Uygulama Entegrasyonu ve Veri Paylaşımı
Uygulamamız, çeşitli harici uygulamalarla veri paylaşımı yapabilmektedir:
- **CSV Dışa Aktarma**: Tüm işlem verilerini CSV formatında dışa aktarma ve paylaşma
  - Mail uygulaması ile gönderme
  - Mesajlar ile paylaşma
  - Notlar uygulamasına kaydetme
  - Dosyalar uygulamasına kaydetme
- **Sistem Ayarları Entegrasyonu**: Bildirim izinleri için Ayarlar uygulamasına yönlendirme
- **App Store Bağlantısı**: Uygulama değerlendirmesi için App Store'a yönlendirme
- **Safari Entegrasyonu**: Gizlilik politikası ve kullanım koşulları için web tarayıcı açma

## 🌟 Özellikler

### 📊 Kapsamlı Dashboard
- Anlık finansal durumunuzu görüntüleme
- Gelir ve gider dengesi takibi
- Görsel grafikler ve istatistikler
- Özelleştirilebilir zaman aralıkları (haftalık, aylık, yıllık)

### 💰 İşlem Yönetimi
- Kolay gelir/gider ekleme
- Kategorilere göre sınıflandırma
- Tekrarlayan işlem desteği
- Detaylı notlar ve açıklamalar ekleme

### 🔔 Akıllı Bildirimler
- Önemli işlemler için hatırlatmalar
- Tekrarlayan ödemeler için uyarılar
- Özelleştirilebilir bildirim ayarları

### 📈 Analitik ve Raporlama
- Detaylı harcama analizi
- Kategori bazlı raporlar
- Trend analizi ve tahminler
- İhraç edilebilir finansal raporlar

## 🛠 Teknik Özellikler

- **SwiftUI** ile modern ve duyarlı kullanıcı arayüzü
- **SwiftData** ile güvenli ve etkili veri yönetimi
- **Charts** framework'ü ile gelişmiş grafik gösterimleri
- Yerel bildirim sistemi entegrasyonu
- MVVM mimari deseni

## 💡 Kullanım

1. Uygulamayı başlatın
2. Ana dashboard'dan finansal durumunuzu görüntüleyin
3. "+" butonuna tıklayarak yeni işlem ekleyin
4. İşlem detaylarını (miktar, kategori, tarih vb.) girin
5. İsterseniz tekrarlayan işlem olarak ayarlayın
6. Bildirim tercihlerinizi belirleyin
7. Analitik bölümünden detaylı raporları inceleyin

## 🎯 Gelecek Özellikler

- Bütçe planlama ve hedef belirleme
- Çoklu hesap desteği
- Gelişmiş kategori yönetimi
- Finansal tavsiyeler ve ipuçları
- Döviz kurları entegrasyonu
- Fatura tarama ve otomatik giriş

