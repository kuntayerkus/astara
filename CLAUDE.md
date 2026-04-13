# Astara iOS — Claude Bağlamı

**Uygulama:** Astara | **Tagline:** "Ad astra per aspera" | **Platform:** iOS 17+
**Hedef:** CHANI/Co-Star ölçeğinde astroloji uygulaması — Türkiye'den başlayıp global'e açılacak
**Hedef kitle:** Gen-Z / Y kuşağı (18-35), kadın ağırlıklı, önce Türkiye → sonra global
**Ton:** Hafif ironik, samimi, "arkadaşınla sohbet" enerjisi — Co-Star'ın soğukluğu ile CHANI'nin sıcaklığı arasında
**Diller:** Türkçe (v1), İngilizce (v2), İspanyolca/Portekizce (v3)

---

## Brand Identity

### İsim Kökeni
- **Astara** ← Latince "astra" (yıldızlar) + evrensel "-a" sonu
- **Motto:** "Ad astra per aspera" — Yıldızlara zorluklar aracılığıyla
- **Brand promise:** Hayat zor, ama yıldızlar sana yol gösteriyor
- **Kısa tagline (TR):** "Yıldızlara, zorluklarla."
- **Kısa tagline (EN):** "Through hardships, to the stars."

### Brand Voice
- Samimi ama bilgili (bir arkadaşın ki o arkadaş aynı zamanda astrolog)
- İronik ama kırıcı değil (Co-Star gibi soğuk değil, ama CHANI gibi "yoga retreat" de değil)
- Empowering — "senin haritanı okuyoruz, kaderini değil"
- Lokalizasyon: TR'de daha samimi/ironik, EN'de daha witty/poetic

### Bundle & Domain
- **Bundle ID:** `com.getastara.app`
- **Domain:** astara.app (veya getastara.com)
- **Deep links:** `astara://chart`, `astara://daily`, `astara://compatibility`
- **Universal Links:** `https://astara.app/chart` → native app
- **Social:** @astara.app (IG), @astaraapp (X/Twitter)

---

## Teknoloji Yığını

| Katman | Teknoloji | Neden |
|--------|-----------|-------|
| **UI Framework** | SwiftUI (iOS 17+) | Deklaratif, hızlı iterasyon, widget desteği |
| **Mimari** | TCA (The Composable Architecture) | Testable, modüler state yönetimi |
| **Networking** | Swift Concurrency (async/await) + URLSession | Native, lightweight |
| **Persistence** | SwiftData + KeychainAccess | Yerel veri + güvenli token saklama |
| **Push** | APNs + Firebase Cloud Messaging | Viral bildirim stratejisi |
| **Analytics** | PostHog (privacy-first) | GDPR/KVKK uyumlu |
| **Payments** | StoreKit 2 | Abonelik yönetimi |
| **Charts** | SwiftUI Canvas + Custom Drawing | Natal chart wheel rendering |
| **Auth** | Sign in with Apple + Email/OTP | Global uyumluluk |
| **Backend (v1)** | Mevcut Vercel API + swiss.grio.works VPS | Var olan altyapıyı kullan |
| **Backend (v2)** | Supabase (PostgreSQL + Auth + Realtime) | Sosyal özellikler + global scale |
| **CI/CD** | Xcode Cloud + Fastlane | App Store dağıtım |
| **Min iOS** | 17.0 | SwiftData, Observable macro, WidgetKit interactivity |
| **Lokalizasyon** | String Catalogs (.xcstrings) | Multi-language ready from day 1 |

---

## Proje Yapısı

```
Astara/
├── App/
│   ├── AstaraApp.swift                 # @main entry point
│   ├── AppDelegate.swift               # Push notification registration
│   └── Configuration/
│       ├── Environment.swift           # API keys, base URLs (xcconfig based)
│       ├── AppConstants.swift          # Sabit değerler
│       └── Localization.swift          # Dil yönetimi (TR/EN/ES)
│
├── Core/
│   ├── Models/
│   │   ├── User.swift                  # Kullanıcı profili (doğum bilgileri)
│   │   ├── BirthChart.swift            # Natal harita modeli
│   │   ├── Planet.swift                # Gezegen pozisyonu
│   │   ├── ZodiacSign.swift            # 12 burç enum (localized)
│   │   ├── House.swift                 # Ev sistemi
│   │   ├── Aspect.swift               # Açı modeli
│   │   ├── DailyHoroscope.swift        # Günlük yorum
│   │   ├── Compatibility.swift         # Uyum skoru
│   │   ├── Transit.swift              # Transit hareketi
│   │   └── Retrograde.swift           # Retro takvimi
│   │
│   ├── Services/
│   │   ├── APIClient.swift             # Base HTTP client (async/await)
│   │   ├── ChartService.swift          # /api/harita proxy
│   │   ├── HoroscopeService.swift      # /api/horoscope proxy
│   │   ├── GeoService.swift            # /api/geo proxy
│   │   ├── TimezoneService.swift       # /api/timezone proxy
│   │   ├── NotificationService.swift   # Push notification handler
│   │   ├── CacheService.swift          # Offline data cache
│   │   └── SubscriptionService.swift   # StoreKit 2 entegrasyonu
│   │
│   ├── Engine/
│   │   ├── AstrologyEngine.swift       # Keplerian fallback hesaplamaları
│   │   ├── CompatibilityEngine.swift   # Element bazlı uyum skoru
│   │   ├── AspectCalculator.swift      # Açı hesaplama
│   │   └── HouseCalculator.swift       # Ev sistemi (Placidus)
│   │
│   └── Utilities/
│       ├── DateFormatters.swift
│       ├── IANATimezone.swift           # Timezone handling (ASLA UTC çevirme)
│       ├── Haptics.swift
│       └── ShareManager.swift          # Screenshot-friendly paylaşım
│
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift        # "Ad astra per aspera" intro
│   │   ├── BirthDataInputView.swift    # Doğum verisi toplama
│   │   ├── CitySearchView.swift        # Şehir arama (GeoNames)
│   │   └── ChartRevealView.swift       # İlk harita gösterimi (animasyonlu)
│   │
│   ├── Home/
│   │   ├── HomeView.swift              # Ana sayfa (daily hub)
│   │   ├── DailyCardView.swift         # Günlük kart (energy, theme, tip)
│   │   ├── PlanetPositionsView.swift   # Gökyüzü widget
│   │   ├── ElementEnergyView.swift     # Ateş/Toprak/Hava/Su barları
│   │   └── RetroAlertBanner.swift      # Aktif retro uyarısı
│   │
│   ├── Chart/
│   │   ├── ChartView.swift             # Natal harita ana ekran
│   │   ├── ChartWheelView.swift        # SwiftUI Canvas çizim
│   │   ├── PlanetDetailSheet.swift     # Gezegen detay bottom sheet
│   │   ├── HouseDetailSheet.swift      # Ev detay
│   │   ├── AspectGridView.swift        # Açı tablosu
│   │   ├── AIInterpretationView.swift  # Gemini AI yorum
│   │   └── ChartShareView.swift        # Paylaşım kartı (screenshot-ready)
│   │
│   ├── DailyHoroscope/
│   │   ├── DailyHoroscopeView.swift    # Günlük yorum ana ekran
│   │   ├── SignSelectorView.swift      # Burç seçici (carousel)
│   │   ├── HoroscopeCardView.swift     # Yorum kartı (energy, text, tip)
│   │   └── ArchiveView.swift           # Geçmiş günler
│   │
│   ├── Compatibility/
│   │   ├── CompatibilityView.swift     # Uyum ana ekran
│   │   ├── SignPairSelector.swift      # İki burç seçimi
│   │   ├── ScoreRingView.swift         # Circular progress (0-100%)
│   │   └── CompatibilityDetailView.swift # Detaylı analiz
│   │
│   ├── Transits/
│   │   ├── TransitsView.swift          # Transit hareketi listesi
│   │   ├── RetroCalendarView.swift     # Retro takvimi
│   │   └── TransitImpactView.swift     # "Bu seni nasıl etkiler?"
│   │
│   ├── Social/
│   │   ├── FriendsListView.swift       # Arkadaş listesi
│   │   ├── AddFriendView.swift         # Arkadaş ekleme (QR + handle)
│   │   ├── FriendChartView.swift       # Arkadaş haritası
│   │   ├── SynastryView.swift          # İki harita karşılaştırma
│   │   └── ShareCardView.swift         # Sosyal medya paylaşım kartı
│   │
│   ├── Explore/
│   │   ├── ExploreView.swift           # Keşfet/Blog
│   │   ├── ArticleView.swift           # Blog yazısı detay
│   │   ├── QuizView.swift              # Astroloji quiz
│   │   └── LearnView.swift             # "Astroloji 101" eğitim
│   │
│   ├── Profile/
│   │   ├── ProfileView.swift           # Profil & ayarlar
│   │   ├── EditBirthDataView.swift     # Doğum verisini düzenle
│   │   ├── NotificationSettingsView.swift # Bildirim tercihleri
│   │   └── SubscriptionView.swift      # Astara Premium
│   │
│   └── Widgets/
│       ├── DailyWidget.swift           # Home screen widget (günlük enerji)
│       ├── MoonPhaseWidget.swift       # Ay fazı widget
│       └── RetroWidget.swift           # Aktif retro uyarı widget
│
├── DesignSystem/
│   ├── Theme/
│   │   ├── AstaraColors.swift          # Renk paleti
│   │   ├── AstaraTypography.swift      # Font sistemi
│   │   ├── AstaraSpacing.swift         # 4pt grid system
│   │   └── AstaraShadows.swift         # Glow efektleri
│   │
│   ├── Components/
│   │   ├── AstaraButton.swift          # Primary/Secondary/Ghost button
│   │   ├── AstaraCard.swift            # Glassmorphism kart
│   │   ├── AstaraTextField.swift       # Custom input
│   │   ├── ZodiacIcon.swift            # 12 burç ikonları
│   │   ├── PlanetIcon.swift            # Gezegen sembolleri
│   │   ├── GlowingRing.swift           # Animasyonlu halka
│   │   ├── ShimmerView.swift           # Loading skeleton
│   │   ├── ToastView.swift             # Bildirim toast
│   │   └── GradientBackground.swift    # Ana arka plan gradient
│   │
│   └── Animations/
│       ├── ChartRevealAnimation.swift  # Harita açılış animasyonu
│       ├── StarfieldView.swift         # Yıldız alanı parallax
│       └── PulseAnimation.swift        # Nabız efekti
│
├── Resources/
│   ├── Assets.xcassets/                # Renk setleri, ikonlar, görseller
│   ├── Fonts/                          # Cormorant Garamond + Plus Jakarta Sans
│   ├── Localizable.xcstrings           # Türkçe + İngilizce + İspanyolca
│   └── Lottie/                         # Animasyon dosyaları
│
└── Tests/
    ├── UnitTests/
    │   ├── AstrologyEngineTests.swift
    │   ├── CompatibilityEngineTests.swift
    │   └── APIClientTests.swift
    └── UITests/
        ├── OnboardingUITests.swift
        └── ChartFlowUITests.swift
```

---

## Özellik Matrisi (MVP → v2 → v3)

### MVP (v1.0) — App Store İlk Yayın (Türkiye)

| Özellik | Öncelik | Kaynak |
|---------|---------|--------|
| Onboarding (doğum verisi toplama) | P0 | Yeni |
| Doğum haritası görselleştirme | P0 | VPS + Canvas |
| Günlük burç yorumu | P0 | daily-horoscope.json |
| Element enerji seviyeleri | P0 | daily-energy.json |
| Gezegen pozisyonları | P0 | planet-positions.json |
| Retro takvimi | P1 | retro-calendar.json |
| Burç uyumu (basit) | P1 | Yerel hesaplama |
| Push notifications (günlük) | P1 | APNs |
| Profil & ayarlar | P1 | SwiftData |
| Home screen widget | P2 | WidgetKit |
| Offline destek | P2 | Cache |

### v2.0 — Sosyal & Global (İngilizce eklenir)

| Özellik | Kaynak |
|---------|--------|
| İngilizce lokalizasyon | String Catalogs |
| Arkadaş sistemi (Co-Star tarzı) | Supabase backend |
| Synastry (iki harita karşılaştırma) | VPS |
| AI yorumlar (Gemini) multi-language | /api/horoscope |
| Transit takibi ("bugün seni ne etkiliyor") | VPS + yerel |
| Provoke edici bildirimler (viral) | AI-generated |
| Blog/Keşfet bölümü | CMS (Contentful veya Sanity) |
| Chart paylaşım kartları (Instagram Stories) | ShareManager |

### v3.0 — Premium & Scale (ES/PT eklenir)

| Özellik | Kaynak |
|---------|--------|
| Premium abonelik (StoreKit 2) | Yeni |
| İspanyolca/Portekizce | String Catalogs |
| Ay fazı ritüelleri & meditasyon | İçerik |
| Yıllık forecast | AI + Astroloji |
| Celebrity chart analizi | İçerik |
| Apple Watch komplikasyonu | WatchKit |
| Live Activities (transit uyarıları) | ActivityKit |
| Siri Shortcuts ("What's my energy today?") | AppIntents |
| Android (Kotlin Multiplatform veya React Native) | Ayrı proje |

---

## Tasarım Sistemi

### Renk Paleti

```swift
enum AstaraColors {
    // Ana gradient arka plan
    static let backgroundStart = Color(hex: "#0d0a14")  // Koyu mor-siyah
    static let backgroundEnd = Color(hex: "#1c1520")    // Koyu mor

    // Astara Gold (primary accent)
    static let gold = Color(hex: "#C9A96E")             // Ana altın vurgu
    static let goldLight = Color(hex: "#E8D5A3")        // Açık altın
    static let goldDark = Color(hex: "#8B7340")         // Koyu altın

    // Ember paleti (ateş/tutku)
    static let ember50 = Color(hex: "#FFF7ED")
    static let ember400 = Color(hex: "#FB923C")
    static let ember600 = Color(hex: "#EA580C")

    // Sage paleti (toprak/sakinlik)
    static let sage400 = Color(hex: "#4ADE80")
    static let sage600 = Color(hex: "#16A34A")

    // Mist paleti (hava/düşünce)
    static let mist400 = Color(hex: "#94A3B8")
    static let mist600 = Color(hex: "#475569")

    // Element renkleri
    static let fire = Color(hex: "#EF4444")
    static let earth = Color(hex: "#A3E635")
    static let air = Color(hex: "#38BDF8")
    static let water = Color(hex: "#818CF8")

    // Semantic
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.4)
    static let cardBackground = Color.white.opacity(0.05)
    static let cardBorder = Color.white.opacity(0.08)
}
```

### Tipografi

```swift
enum AstaraTypography {
    // Başlıklar: Cormorant Garamond (serif, zarif, astrolojik his)
    static let displayLarge = Font.custom("CormorantGaramond-Bold", size: 34)
    static let displayMedium = Font.custom("CormorantGaramond-SemiBold", size: 28)
    static let titleLarge = Font.custom("CormorantGaramond-Medium", size: 22)
    static let titleMedium = Font.custom("CormorantGaramond-Medium", size: 18)

    // Body: Plus Jakarta Sans (modern, okunaklı)
    static let bodyLarge = Font.custom("PlusJakartaSans-Regular", size: 17)
    static let bodyMedium = Font.custom("PlusJakartaSans-Regular", size: 15)
    static let bodySmall = Font.custom("PlusJakartaSans-Regular", size: 13)
    static let labelLarge = Font.custom("PlusJakartaSans-SemiBold", size: 15)
    static let labelMedium = Font.custom("PlusJakartaSans-SemiBold", size: 13)
    static let caption = Font.custom("PlusJakartaSans-Regular", size: 11)
}
```

### Kart Stili (Glassmorphism)

```swift
struct AstaraCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AstaraColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }
}
```

---

## API Entegrasyonu

### Base Configuration

```swift
enum APIEnvironment {
    case production
    case staging

    var baseURL: URL {
        switch self {
        case .production: URL(string: "https://astara.app/api")!
        case .staging: URL(string: "http://localhost:3000/api")!
        }
    }

    // Mevcut merkurmagduru.com API'leri (v1'de bridge olarak kullanılır)
    var legacyBaseURL: URL {
        URL(string: "https://merkurmagduru.com/api")!
    }

    var vpsURL: URL {
        URL(string: "https://swiss.grio.works")!
    }
}
```

### Endpoint Mapping

| iOS Feature | API Endpoint | Method | Cache Süresi |
|-------------|-------------|--------|-------------|
| Doğum haritası | `/api/harita` | GET | 1 saat |
| AI yorum | `/api/horoscope` | POST | Session |
| Şehir arama | `/api/geo` | GET | 24 saat |
| Timezone | `/api/timezone` | GET | 7 gün |
| Günlük veri | `/data/daily-horoscope.json` | GET (static) | 6 saat |
| Enerji | `/data/daily-energy.json` | GET (static) | 6 saat |
| Gezegenler | `/data/planet-positions.json` | GET (static) | 6 saat |
| Retro | `/data/retro-calendar.json` | GET (static) | 7 gün |

### Rate Limiting (iOS tarafı)

```swift
// Harita: max 30 req/dk — debounce + cache
// Horoscope: max 10 req/saat — aggressive cache
// Geo: max 3 req/sn — debounce 300ms
```

---

## Kritik Kurallar (iOS)

### Timezone (ASLA değiştirme — web ile aynı kural)
- iOS **hiçbir zaman** UTC çevirimi yapmaz
- `TimeZone.identifier` (IANA ID) ham olarak VPS'e gönderilir
- VPS, pytz ile DST-aware çevirimi kendisi yapar
- Format: `Europe/Istanbul`, `America/New_York`

### VPS Gezegen İsimleri (Türkçe karakter YOK)
```swift
enum PlanetKey: String, CaseIterable {
    case gunes, ay, merkur, venus, mars
    case jupiter, saturn, uranus, neptun, pluton
    case yukselen, mc, vertex
}
// ⚠️ uranus (ü değil u), neptun (ü değil u)
```

### Kesinlikle yapma (iOS)
- TimeZone → UTC çevirimi yapma (VPS halleder)
- Gezegen isimlerinde Türkçe karakter kullanma
- VPS IP'sini hardcode etme — `swiss.grio.works` kullan
- Horoscope API'sine validasyonsuz burç adı gönderme (prompt injection riski)
- Kullanıcı verisini sanitize etmeden gösterme
- API key'leri source code'a koyma (xcconfig + Keychain)
- Push notification'da kişisel veri gönderme (payload'da sadece trigger)
- "Merkür Mağduru" branding'i kullanma — bu artık **Astara**

### Yapılması gerekenler
- Her API çağrısında `X-API-Key` header ekle (VPS çağrıları)
- User-Agent header: `Astara-iOS/1.0`
- Certificate pinning uygula (swiss.grio.works için)
- Offline-first: Cache'den göster, arka planda güncelle
- Deep link desteği: `astara://chart`, `astara://daily`
- Universal Links: `https://astara.app/chart` → native app
- Tüm UI string'leri String Catalog'dan çek (hardcode Türkçe yazma)

---

## Push Notification Stratejisi

### Bildirim Türleri

| Tür | Saat | Ton | Örnek (TR) | Örnek (EN) |
|-----|------|-----|------------|------------|
| **Günlük Enerji** | 08:00 | İronik-samimi | "Bugün element enerjin %80 su — ya ağlarsın ya çay içersin" | "Your energy is 80% water today — cry it out or make tea" |
| **Transit Uyarısı** | Olay anı | Bilgilendirici | "Mars Koç'a girdi. Sabır stokların tehlikede." | "Mars enters Aries. Your patience? Gone." |
| **Retro Başlangıç** | Retro günü | Dramatik | "Merkür retrosu başladı. Eski sevgilinden mesaj gelebilir. Engelle." | "Mercury retrograde just started. Your ex might text. Block." |
| **Uyum Güncellemesi** | 14:00 (rastgele) | Provoke edici | "Sen ve [arkadaş]: Bugün ikiniz de gergin. Mesaj atma." | "You and [friend]: Both tense today. Don't text." |
| **Haftalık Özet** | Pazar 10:00 | Sıcak | "Bu hafta 3 transit geçirdin ve hâlâ ayaktasın." | "3 transits this week and you're still standing." |

### Viral Bildirim Kuralları
- Kısa tut (max 2 cümle)
- Screenshot-friendly (arkadaşa atılabilir olmalı)
- Kişiselleştirilmiş (kullanıcının burç verisine göre)
- Haftada max 5 bildirim (spam olma)
- "Rahatsız Etme" saatleri: 23:00-07:00
- **Her bildirim hem TR hem EN versiyonu olmalı** (locale'e göre gönderilir)

---

## Monetizasyon

### Freemium Model

**Ücretsiz (Astara Free):**
- Günlük burç yorumu (güneş burcu)
- Temel doğum haritası (gezegenler + evler)
- Element enerji seviyeleri
- Retro takvimi
- 1 uyum testi/gün
- Reklam yok (asla — premium brand algısı)

**Astara Premium:**
- **TR fiyat:** ₺79.99/ay veya ₺599.99/yıl
- **Global fiyat:** $7.99/ay veya $59.99/yıl
- Yükselen burç günlük yorumu
- AI kişisel yorum (Gemini)
- Tam transit takibi
- Sınırsız uyum testi
- Synastry (iki harita karşılaştırma)
- Asteroid pozisyonları
- Geçmiş gün yorumları (arşiv)
- Özel paylaşım kartları (Astara watermark'lı)
- Ay ritüelleri & meditasyon

### StoreKit 2 Ürünleri
```swift
enum AstaraProduct: String {
    case monthlyPremium = "com.astara.premium.monthly"
    case yearlyPremium = "com.astara.premium.yearly"
    case lifetimePremium = "com.astara.premium.lifetime"
}
```

---

## Onboarding Akışı

```
1. Splash (Astara logosu + yıldız alanı animasyonu)
     ↓
2. "Ad astra per aspera" (3 slide: brand story + uygulama ne yapar)
     • "Yıldızlara, zorluklarla."
     • "Haritanı oku. Enerjini anla. Yolunu bul."
     • "Her gün, gökyüzü sana bir şey söylüyor."
     ↓
3. Doğum Tarihi (DatePicker, "Gezegenlerin neredeydi, onu arıyoruz")
     ↓
4. Doğum Saati (TimePicker + "Bilmiyorum" seçeneği → 12:00 + uyarı)
     ↓
5. Doğum Yeri (Şehir arama → GeoNames API)
     ↓
6. Loading (yıldız animasyonu + "Haritanı çiziyoruz...")
     ↓
7. Chart Reveal (dramatik animasyon → tam natal wheel)
     ↓
8. "Güneşin [X], Ayın [Y], Yükselenin [Z]" özet kartı
     ↓
9. Push notification izni ("Gökyüzü sana her gün bir şey söylüyor")
     ↓
10. Ana sayfa
```

---

## Offline & Cache Stratejisi

```swift
enum AstaraCachePolicy {
    case dailyHoroscope     // 6 saat, stale-while-revalidate
    case planetPositions    // 6 saat, stale-while-revalidate
    case dailyEnergy        // 6 saat, stale-while-revalidate
    case retroCalendar      // 7 gün, cache-first
    case birthChart         // Sonsuz (kullanıcının haritası değişmez)
    case geoSearch          // 24 saat
    case timezone           // 7 gün
    case blogArticles       // 3 gün, cache-first
}
```

**Offline davranış:**
- Ana sayfa: Cache'den son veriyi göster + "Son güncelleme: 3 saat önce" badge
- Harita: Daha önce hesaplanmışsa cache'den göster
- Uyum: Tamamen offline çalışır (yerel hesaplama)
- Blog: Cache'deki yazıları göster

---

## Sosyal Özellikler (v2)

### Arkadaş Sistemi
- Kullanıcı adı (unique handle: @ali)
- QR kod ile arkadaş ekleme
- Arkadaşın günlük enerjisini görme
- Synastry (iki harita uyumu)
- "Bugün arkadaşınla [aspect] var" bildirimleri

### Paylaşım Kartları (Instagram Stories)
- Natal chart wheel (transparent bg, story-ready)
- Günlük enerji kartı (dark gradient, altın text)
- Uyum skoru kartı
- "Bugünün gökyüzü" kartı
- Format: 1080×1920px, **Astara watermark** (logo + "astara.app")
- Her kart paylaşıldığında organic growth → watermark = free marketing

---

## Backend Gereksinimleri

### Phase 1 (MVP): Mevcut altyapıyı kullan
- merkurmagduru.com API'leri → CORS'u `astara.app` için aç
- Statik data dosyaları aynı kalır
- VPS değişiklik yok

### Phase 2 (Sosyal): Yeni backend
- **Supabase** (PostgreSQL + Auth + Realtime + Edge Functions)
- Veya kendi backend: **Hono.js** (Edge runtime) + **Turso** (SQLite edge DB)

```
POST /api/auth/apple          — Sign in with Apple
POST /api/auth/email          — Email/OTP login
GET  /api/user/profile        — Profil bilgisi
PUT  /api/user/profile        — Profil güncelleme
POST /api/user/chart          — Harita kaydet
GET  /api/user/chart          — Kayıtlı harita getir
POST /api/friends/add         — Arkadaş ekle
GET  /api/friends/list        — Arkadaş listesi
DELETE /api/friends/:id       — Arkadaş sil
POST /api/notifications/token — APNs token kaydet
GET  /api/content/articles    — Blog yazıları (paginated, i18n)
GET  /api/content/daily/:locale — Lokalize günlük veri
```

### Veritabanı Şeması (v2)
```sql
users (id, apple_id, email, handle, birth_date, birth_time, birth_lat, birth_lng, birth_timezone, locale, created_at)
charts (id, user_id, chart_data_json, created_at)
friendships (id, user_a, user_b, status, created_at)
notification_tokens (id, user_id, apns_token, device_id, created_at)
```

---

## Globalizasyon Stratejisi

### Dil Öncelik Sırası
1. **Türkçe** (v1.0) — Türkiye pazarı, 85M nüfus, astroloji ilgisi çok yüksek
2. **İngilizce** (v2.0) — Global, ABD/UK/Avustralya, en büyük pazar
3. **İspanyolca** (v3.0) — Latin Amerika, 500M+ konuşan, astroloji popüler
4. **Portekizce** (v3.0) — Brezilya, 210M nüfus, astroloji çok yaygın

### Lokalizasyon Kuralları
- Burç isimleri: Her dilde native (Koç/Aries/Aries/Áries)
- Gezegen isimleri: Display'de localize, **VPS'e gönderirken HER ZAMAN İngilizce key**
- Tarih formatları: Locale-aware (DateFormatter.dateStyle)
- Para birimi: StoreKit otomatik (bölgesel fiyatlandırma)
- AI yorumlar: Kullanıcının locale'inde üret (Gemini multilingual)
- Push bildirimler: Kullanıcının diline göre gönder

### Kültürel Adaptasyon
- **TR:** İronik ton, "arkadaş sohbeti" enerjisi, Türkçe deyimler
- **EN:** Witty, slightly sarcastic, pop-culture references
- **ES:** Cálido, directo, references to Latin culture
- Ton kılavuzu her dil için ayrı doküman olarak yazılacak

---

## Test Verisi

### Doğum Haritası Doğrulama

**JFK:** 29/05/1917 15:00, Brookline MA (42.33°N 71.12°W), `America/New_York`
→ ASC Terazi ~20° (199.99°) ✓

**Diana:** 01/07/1961 19:45, Sandringham UK (52.83°N 0.52°E), `Europe/London`
→ ASC Yay ~18° (258.43°) ✓

**Test kullanıcısı:** 15/03/1995 14:30, İstanbul (41.01°N 28.98°E), `Europe/Istanbul`

---

## App Store Bilgileri

### Metadata
- **Uygulama Adı:** Astara — Astrology & Birth Chart
- **Subtitle (TR):** Günlük Astroloji & Doğum Haritası
- **Subtitle (EN):** Daily Horoscope & Natal Chart
- **Kategori:** Lifestyle (Primary), Entertainment (Secondary)
- **Yaş sınırı:** 4+ (astroloji içerik)
- **Diller:** Türkçe (v1), English (v2), Español (v3)

### ASO Keywords (TR)
```
burç, astroloji, doğum haritası, günlük burç, yükselen burç,
merkür retrosu, burç uyumu, natal chart, gezegen, koç, boğa,
ikizler, yengeç, aslan, başak, terazi, akrep, yay, oğlak,
kova, balık, transit, horoscope, astara
```

### ASO Keywords (EN)
```
horoscope, astrology, birth chart, natal chart, zodiac,
daily horoscope, rising sign, mercury retrograde, compatibility,
transit, aries, taurus, gemini, cancer, leo, virgo, libra,
scorpio, sagittarius, capricorn, aquarius, pisces, astara
```

### App Store Description (EN)
```
Astara — Ad astra per aspera.

Your birth chart. Your daily energy. Your cosmic roadmap.

Astara reads the sky so you don't have to. Get hyper-personalized daily 
horoscopes, a stunning natal chart visualization, compatibility scores 
with friends, and real-time transit alerts — all wrapped in an interface 
that's as beautiful as the night sky.

✦ Features:
• Full natal chart with AI-powered interpretations
• Daily energy levels & personalized horoscope
• Real-time planet positions & retrograde alerts
• Zodiac compatibility scoring
• Push notifications that actually understand you
• Beautiful share cards for Instagram Stories

Through hardships, to the stars. ✦
```

### Screenshots (6.7" & 6.5")
1. Günlük enerji kartı (ana sayfa) — "Your daily cosmic energy"
2. Doğum haritası wheel — "Your birth chart, visualized"
3. Burç uyumu — "Are you compatible?"
4. Push notification örneği — "Notifications that get you"
5. Retro takvimi — "Never get caught off guard"
6. Premium özellikler — "Unlock your full chart"

---

## Güvenlik

### API Key Yönetimi
- Tüm secret'lar `.xcconfig` dosyasında (gitignore'da)
- Runtime'da `Bundle.main.infoDictionary` üzerinden oku
- VPS key Keychain'de sakla (ilk login sonrası)
- Certificate pinning: `swiss.grio.works` SSL pin

### Veri Güvenliği
- Doğum verisi: SwiftData (cihazda, iCloud sync opsiyonel)
- Harita cache: Local (hassas veri yok, sadece astronomik pozisyonlar)
- Auth token: Keychain (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
- Analytics: Anonim (kullanıcı ID hash'lenmiş)

### KVKK/GDPR Uyumu
- Açık rıza metni (onboarding sırasında)
- Veri silme butonu (profil → hesabımı sil)
- Analytics opt-out
- Minimum veri toplama (sadece doğum bilgisi + tercihler)
- Data residency: TR kullanıcıları için TR/EU region

---

## Performans Hedefleri

| Metrik | Hedef |
|--------|-------|
| Cold launch → Home | < 2 saniye |
| Harita hesaplama | < 3 saniye (VPS response dahil) |
| Günlük yükleme | < 1 saniye (cache hit) |
| Bellek kullanımı | < 150 MB |
| Pil tüketimi | Minimal (background fetch 15dk) |
| App boyutu | < 50 MB (font + Lottie dahil) |
| Crash-free rate | > 99.5% |
| App Store rating | > 4.7 (CHANI seviyesi) |

---

## Geliştirme Sırası (Sprint Durumu)

### Sprint 1-2: Temel Altyapı ✅ TAMAMLANDI
- [x] Xcode projesi + TCA kurulum + SPM dependencies
- [x] Design system (AstaraColors, AstaraTypography, Components)
- [x] APIClient + CacheService
- [x] SwiftData modelleri
- [x] Onboarding flow ("Ad astra per aspera" intro)

### Sprint 3-4: Harita & Günlük ✅ TAMAMLANDI
- [x] BirthDataInput + CitySearch (GeoNames)
- [x] ChartService → VPS entegrasyonu
- [x] Chart wheel rendering (SwiftUI Canvas)
- [x] Günlük burç veri çekme + gösterim
- [x] Element enerji bileşeni

### Sprint 5-6: Özellikler ✅ TAMAMLANDI
- [x] Uyum hesaplama (yerel engine — CompatibilityEngine)
- [x] Retro takvimi
- [x] Gezegen pozisyonları ekranı
- [x] Push notification (APNs — NotificationService)
- [x] SubscriptionService (StoreKit 2 iskelet — UI bağlantısı launch öncesi)

### Sprint 7-8: Polish (🔄 Aktif — Test Aşaması)
- [x] Astara.entitlements (aps-environment = production)
- [x] PrivacyInfo.xcprivacy (UserDefaults + coarse location)
- [x] .gitattributes (CRLF → LF)
- [x] Release.xcconfig CI secret injection (codemagic.yaml)
- [x] Push permission stub → gerçek UNUserNotificationCenter
- [x] HomeFeature error handling + retry UX
- [x] SwiftData persistence (PersistenceClient, AstaraApp, AppFeature, EditBirthDataView)
- [ ] Unit testler (hedef: 20+)
- [ ] Lottie: gerçek animasyon ekle veya dependency'yi kaldır
- [ ] **LAUNCH ÖNCESI:** SubscriptionView ↔ StoreKit 2 (App Store Connect product ID sonrası)
- [ ] **LAUNCH ÖNCESI:** App Store metadata, screenshots (6.7"), privacy policy URL
- [ ] **LAUNCH ÖNCESI:** App Store distribution CI workflow (codemagic.yaml)
- [ ] TestFlight beta → App Store Review submit

### Sprint 9-10: English & Growth
- [ ] İngilizce lokalizasyon
- [ ] App Store Optimization (EN)
- [ ] Viral bildirim sistemi
- [ ] Paylaşım kartları (Instagram Stories)
- [ ] ASO + UA campaign launch

---

## Mevcut Durum Özeti (2026-04-14)

**Proje şu an test aşamasında.** Kod tamamlandı, App Store submission için kalan şeyler
launch öncesi yapılacak (screenshots, StoreKit ürün bağlantısı, metadata).

**Tamamlanan altyapı:**
- Tüm feature'lar (Onboarding, Home, Chart, DailyHoroscope, Compatibility, Profile)
- TCA mimarisi tam entegre
- 140 lokalizasyon key (TR + EN)
- SwiftData persistence (PersistenceClient + ModelContainer.astara)
- CI/CD: Codemagic (TestFlight deploy, build-test, SwiftLint)

**Kritik dosyalar (son değişiklikler):**
- `Astara/Astara.entitlements` — APNs entitlement
- `Astara/PrivacyInfo.xcprivacy` — Apple privacy manifest
- `Astara/Core/Services/PersistenceClient.swift` — SwiftData dependency
- `Astara/App/AppFeature.swift` — SwiftData'ya geçildi (UserDefaults kaldırıldı)

---

## Referanslar

- **Mevcut web:** https://merkurmagduru.com (data source, v1 bridge)
- **VPS API:** https://swiss.grio.works
- **Hedef domain:** https://astara.app
- **Rakipler:** CHANI (App Store), Co-Star (App Store), The Pattern, Sanctuary
- **Tasarım ilham:** Co-Star (minimal dark), CHANI (sıcak tonlar), Hinge (onboarding UX)
- **Teknik ilham:** TCA examples, PointFree.co, SwiftUI by Example
- **Brand ilham:** "Ad astra per aspera" — NASA, Kansas state motto, Virgil's Aeneid
