
# Digital Maintenance & Issue Tracker

Endüstriyel saha ekipmanlarının (HMI, LED Panel, LCD, Endüstriyel PC) arıza tespit ve bakım süreçlerini dijitalleştirmek amacıyla geliştirilmiş, kurumsal standartlarda bir cross-platform Flutter uygulamasıdır.

Sistem, rol tabanlı erişim kontrolü (Role-Based Access Control) mimarisine sahip olup iki temel kullanıcı rolüne göre özelleştirilmiştir:

| Rol | Sistem Yetkileri & Operasyon Kapsamı |
|-----|--------------------------------------|
| **Saha Personeli (Personnel)** | Envanterdeki cihazları listeler, anlık renk kodlu sağlık durumlarını günceller (Working / Faulty / Missing), arıza durumlarında dahili kamera ile fotoğraf kanıtı çeker ve sisteme real-time rapor gönderir. |
| **Yönetici (Admin)** | Sahadan gelen tüm arıza bildirimlerini kronolojik canlı akışla izler, fotoğraf kanıtlarını inceler, envanter sağlık metriklerini grafiklerle takip eder ve mevcut oturumunu kapatmadan sisteme yeni kullanıcı (Admin/Personel) ekler. |

---

##  İçindekiler

- [Gereksinimler](#-gereksinimler)
- [Kurulum & Lokalde Ayağa Kaldırma](#-kurulum--lokalde-ayağa-kaldırma)
- [Firebase Yapılandırma Adımları](#-firebase-yapılandırma-adımları)
- [Test Hesapları & Yetkilendirme (Admin Access)](#-test-hesapları--yetkilendirme-admin-access)
- [Kullanım Kılavuzu & Ekran Görüntüleri (Usage)](#-kullanım-kılavuzu--ekran-görüntüleri-usage)
- [Proje Mimarisi & Klasör Yapısı](#-proje-mimarisi--klasör-yapısı)
- [CI/CD Otomasyon Boru Hattı (Pipeline)](#-cicd-otomasyon-boru-hattı-pipeline)

---

## 🛠️ Gereksinimler

Uygulamayı yerel ortamınızda sorunsuz şekilde ayağa kaldırmak için aşağıdaki bağımlılıkların ve SDK sürümlerinin kurulu olması gerekmektedir:

- **Flutter SDK:** `v3.10.1` veya üzeri (Dart SDK `^3.10.1`)
- **Firebase CLI:** `v12.0.0` veya üzeri (`npm install -g firebase-tools` ile yüklenebilir)
- **Android SDK:** API Level 33 ve üzeri (Android derlemeleri için)
- **Xcode:** `v14.0` veya üzeri (iOS derlemeleri için - macOS gereklidir)
- Aktif bir **Firebase Projesi**

---

##  Kurulum & Lokalde Ayağa Kaldırma

### 1. Depoyu Klonlayın ve Proje Dizinine Geçin
```bash
git clone <repository-url>
cd digital_maintenance_tracker

```

### 2. Paket Bağımlılıklarını Çekin

```bash
flutter pub get

```

### 3. Statik Kod Analizi ve Kalite Kontrolü

Proje, kurumsal kod mimarisine ve katı lint kurallarına tam uyumlu olarak **sıfır uyarı (zero warnings)** politikasıyla geliştirilmiştir. Kod kalitesini doğrulamak için:

```bash
flutter analyze

```

### 4. Birim Testleri Çalıştırın

```bash
flutter test

```

### 5. Uygulamayı Yerelde Çalıştırın

```bash
flutter run

```

---

##  Firebase Yapılandırma Adımları

Uygulamanın bulut tabanlı servislerle eşzamanlı çalışabilmesi için bir Firebase projesine bağlanması şarttır.

### Adım 1: Bulut Servislerinin Konsolda Aktif Edilmesi

[Firebase Console](https://console.firebase.google.com/) üzerinden yeni bir proje oluşturun ve sol menüden şu 3 servisi aktif edin:

1. **Authentication (Kimlik Doğrulama):** `Build > Authentication > Sign-in method` sekmesinden **Email/Password** sağlayıcısını aktif edin.
2. **Cloud Firestore (NoSQL Veritabanı):** `Build > Firestore Database` sekmesinden veritabanını **Start in test mode** olarak oluşturun.
3. **Cloud Storage (Medya Deposu):** `Build > Storage` sekmesinden depolama alanını test modunda aktif edin.

### Adım 2: Projenin CLI ile Firebase'e Bağlanması (FlutterFire CLI)

```bash
# 1. Firebase hesabınızla giriş yapın
firebase login

# 2. FlutterFire CLI aracını global etkinleştirin
dart pub global activate flutterfire_cli

# 3. Proje kök dizininde çalıştırın
flutterfire configure

```

*Bu komut tamamlandığında `lib/firebase_options.dart` dosyası tüm platform anahtarlarıyla otomatik olarak üretilecektir.*

---

##  Test Hesapları & Yetkilendirme (Admin Access)

>  **Önemli Güvenlik Bilgisi:** Sistem güvenliği ve rol suistimallerini engellemek adına, uygulamada dışarıya açık serbest bir "Yönetici (Admin) Kayıt Ol" ekranı bulunmamaktadır. İnceleme ekibinin platformlar arası anlık (real-time) veri akışını ve rol hiyerarşisini kesintisiz deneyimleyebilmesi için aşağıdaki gerçek hesaplar Firebase üzerinde hazır tanımlanmıştır:

###  Hazır Kimlik Bilgileri Tablosu

| Kullanıcı Rolü | E-posta (Email) | Şifre (Password) | Önerilen Test Senaryosu |
| --- | --- | --- | --- |
|  **Yönetici (Admin 1)** | `admin@test.com` | `123456` | Rapor akışını canlı izleme, anlık fotoğraf kontrolü, envanter istatistik takibi ve yeni personel ekleme. |
|  **Yönetici (Admin 2)** | `admin2@test.com` | `123456` | Eşzamanlı çoklu yönetici takibi ve bulut senkronizasyon doğrulamaları. |
|  **Saha Personeli** | `user@test.com` | `123456` | Cihaz durum güncelleme işlemleri, kameradan kanıt yükleme ve bildirim gönderme akışı. |

### Arka Plan Rol Yönetim Mimarisi

Kullanıcı giriş yaptığında, uygulama Firebase Auth servisinden dönen `UID` değerini alır ve Firestore'daki `users/{uid}` dokümanındaki `role` alanını sorgular:

```
role == "admin"      →  Yönetici Konsolu (Admin Dashboard) paneline yönlendirilir.
role == "personnel"  →  Saha Personeli (Field Portal) ekranına yönlendirilir.

```

---

##  Kullanım Kılavuzu & Ekran Görüntüleri (Usage)

Uygulamanın işlevsel akış adımları, dökümandaki tüm isterleri eksiksiz karşılayacak şekilde aşağıda ekran görüntüleriyle desteklenerek senaryolaştırılmıştır:

###  1. Kimlik Doğrulama & Rol Karşılama

Uygulama başlatıldığında kullanıcıyı premium indigo-dark temalı bir giriş arayüzü karşılar. Başarılı girişte rol kontrolü arka planda tamamlanarak doğru ekrana yönlendirme yapılır.

###  2. Saha Personeli Portalı & Canlı Durum Güncelleme

Saha personeli hesabı (`user@test.com`) ile giriş yapıldığında, envanter listesi renk kodlu sağlık durumlarıyla gelir.

* **Arıza Bildirim Akışı:** Personel listeden bir cihaza dokunduğunda alttan işlem paneli (`BottomSheet`) açılır. Durum **Faulty (Arızalı)** seçildiği an cihaz kamerası tetiklenir, çekilen arıza fotoğrafı bytes formatında işlenerek Firebase Storage'a yüklenir ve rapora eklenir.

###  3. Merkezi Yönetici Portalı (Admin Dashboard)

Yöneticiler, saha operasyonlarının tüm çıktılarını ve kullanıcı yönetimini tek bir ekrandan, üst sekmeler (TabBar) aracılığıyla eşzamanlı (real-time) olarak izler.

|  3.1. Canlı Rapor Akışı |  3.2. Envanter Sağlık Metrikleri | 3.3. Kesintisiz Kullanıcı Tanımlama |
| --- | --- | --- |
|  |  |  |
| Personelin sahadan anlık gönderdiği fotoğraflı ve zaman damgalı tüm arıza bildirimleri kronolojik sırada en üstte canlı akar. | Sistem genelindeki çalışan, arızalı ve eksik cihaz sayısal dağılımlarını kartlarla özetler. Test için demo veri yükleme butonuna sahiptir. | Yönetici, **kendi oturumunu kapatmak zorunda kalmadan** sisteme yeni admin veya personel tanımlayabilir. Arka planda ikincil Firebase instance'ı yönetilir. |

---

##  Proje Mimarisi & Klasör Yapısı

Proje, sürdürülebilir temiz kod prensiplerine (`Clean Code`) uygun olarak katmanlı yapıda kurgulanmıştır:

```text
lib/
├── main.dart                  # Uygulama giriş noktası, tema yönetimi ve ilk yönlendirme
├── firebase_options.dart      # FlutterFire CLI tarafından üretilen yapılandırma dosyası
├── models/                    # Veri Yapıları Katmanı
│   ├── device.dart            # Endüstriyel cihaz veri modeli
│   ├── maintenance_log.dart   # Sahadan gelen arıza/bakım kayıt modeli
│   └── user_model.dart        # Kullanıcı hesap ve rol modeli
├── providers/                 # Durum Yönetimi (State Management)
│   └── auth_provider.dart     # Oturum kontrolü ve rollerin reaktif yönetimi
├── screens/                   # Arayüz Bileşenleri (UI Katmanı)
│   ├── login_screen.dart      # Oturum açma ekranı
│   ├── admin_screen.dart      # Yönetici konsolu (3 fonksiyonel sekmeli ana gövde)
│   └── personnel_screen.dart  # Saha personeli listeleme ve kamera ekranı
└── services/                  # Altyapı Servisleri (Infrastructure)
    └── firebase_service.dart  # Firebase Auth, Firestore ve Storage motoru

```

###  Temel Paket Bağımlılıkları Tablosu

| Paket Adı | Sürüm | Kullanım Amacı |
| --- | --- | --- |
| `firebase_core` | ^4.10.0 | Firebase çekirdek servislerinin uygulamada başlatılması. |
| `firebase_auth` | ^6.5.2 | Güvenli e-posta/şifre tabanlı kimlik doğrulama işlemleri. |
| `cloud_firestore` | ^6.5.0 | Canlı (real-time) NoSQL veri senkronizasyonu ve akışları (`Streams`). |
| `firebase_storage` | ^13.4.2 | Çekilen arıza fotoğraflarının bulut ortamında depolanması. |
| `image_picker` | ^1.2.2 | Cihaz kamerasına erişim ve fotoğraf çekim süreçleri. |
| `provider` | ^6.1.5+1 | Reaktif UI güncellemeleri ve merkezi state takibi. |
| `intl` | ^0.20.2 | Zaman damgalarının (Timestamp) tarih/saat formatına çevrilmesi. |

---

##  CI/CD Otomasyon Boru Hattı (Pipeline)

Projede, dökümandaki istek doğrultusunda otomatize edilmiş bir entegrasyon ve dağıtım hattı kurulmuştur. Yapılandırma dosyasına `.github/workflows/firebase-app-distribution.yml` adresinden erişilebilir.

### Pipeline Adımları (Job Steps)

1. **Repository Checkout:** Proje kaynak kodları sanal makineye çekilir.
2. **Setup Java JDK 17:** Android derleme süreçleri için Java 17 ortamı kurulur.
3. **Setup Flutter SDK:** Flutter kararlı (`stable`) SDK kanalı kurulur.
4. **Get Dependencies:** `flutter pub get` ile bağımlılıklar önbelleğe alınır.
5. **Static Code Analysis:** `flutter analyze` ile kod kalitesi denetlenir.
6. **Execute Unit Tests:** `flutter test` ile yazılmış birim testler çalıştırılır.
7. **Build Release APK:** Analizlerden geçen kod üretim çıktısı üretir: `flutter build apk --release`.
8. **Automated Firebase App Distribution:** Derlenen APK dosyası, test ekibine ulaştırılmak üzere **Firebase App Distribution** platformuna otomatik olarak dağıtılır.

### Gerekli Depo Değişkenleri (Repository Secrets)

GitHub Actions pipeline adımının Firebase'e erişebilmesi için GitHub projenizin `Settings -> Secrets and Variables -> Actions` sekmesinden şu iki anahtarı tanımlamanız gerekmektedir:

* `FIREBASE_APP_ID`: Firebase Android uygulama panelinden alınan benzersiz Uygulama Kimliği.
* `FIREBASE_TOKEN`: `firebase login:ci` komutuyla üretilen kurumsal CI erişim token'ı.
