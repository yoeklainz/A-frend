# AI Buddy Kids — Proje İskeleti

## Bu paket ne içeriyor?
Tam bir "üretime hazır" uygulama tek seferde yazılamayacak kadar büyük bir kapsam
(yüz tanıma, duygu analizi, konuşma tanıma, karakter animasyonları, ebeveyn paneli,
bulut senkronizasyonu...). Bu yüzden burada **doğru bir mimari + çalışan bir iskelet**
veriyorum. Üzerine özellikleri modül modül ekleyerek ilerleyebilirsin.

## Klasör Yapısı
```
ai_buddy_kids/
  pubspec.yaml
  lib/
    main.dart
    core/
      models/
        character.dart        # Karakter tanımı (robot, kedi, köpek...)
        user_profile.dart      # Aile üyesi profili
      services/
        database_service.dart  # sqflite ile yerel veritabanı
        tts_service.dart       # Text-to-Speech sarmalayıcı
        stt_service.dart       # Speech-to-Text sarmalayıcı
        chat_service.dart      # Sohbet mantığı (AI cevap üretimi + güvenlik filtresi)
      theme/
        app_theme.dart         # Renkli, çocuk dostu tema
    features/
      character_selection/
        character_selection_screen.dart
      home/
        home_screen.dart       # Tam ekran animasyonlu karakter ekranı
      chat/
        chat_screen.dart
      parental_control/
        parental_control_screen.dart  # Süre limiti, içerik ayarları
```

## Önerilen Paketler (pubspec.yaml içinde)
- `flutter_tts` — Text-to-Speech
- `speech_to_text` — Speech-to-Text (Türkçe destekli)
- `sqflite` + `path` — yerel veritabanı
- `camera` — kamera erişimi
- `google_mlkit_face_detection` — yüz/ifade algılama (ücretsiz, cihaz üzerinde çalışır)
- `google_mlkit_pose_detection` — el sallama gibi hareket algılama
- `shared_preferences` — basit ayarlar (tema, süre limiti)
- `provider` veya `riverpod` — state management

Hepsi **ücretsiz ve açık kaynak** paketler; ekstra ücretli servise ihtiyacın yok.
AI sohbet cevapları için ücretsiz/yerel bir çözüm istiyorsan küçük bir kural-tabanlı
+ şablon sistemiyle başlayıp, bütçen olduğunda bir LLM API'sine bağlanabilirsin
(`chat_service.dart` bu noktada değiştirilecek tek dosya olacak şekilde tasarlandı).

## Çocuk Güvenliği — Kritik Notlar (atlamamalısın)
1. **Yüz verisi cihazdan çıkmasın.** Aile üyesi yüz tanıma verilerini sadece cihazda
   (SQLite + yerel dosya) tut, buluta hiç gönderme.
2. **Ebeveyn onayı zorunlu olsun.** Kamera/mikrofon ilk açılışta ebeveyn PIN'i ile
   onaylanmalı; çocuk tek başına bu izinleri açıp kapatamamalı.
3. **İçerik filtresi iki katmanlı olsun:** hem AI'ya giden istem (prompt) seviyesinde
   hem de AI'dan gelen cevap seviyesinde uygunsuz içerik taraması yap.
4. **Kayıt tutma:** Ebeveyn panelinde çocuğun neyle konuştuğunu özet halinde
   görebileceği bir log tut (çocuğun mahremiyetini de gözeterek dengeli ol).
5. **Süre limiti sunucu tarafında değil cihazda uygulanmalı** — internetsiz de çalışsın.

## Sıradaki Adımlar (öneri sırası)
1. Bu iskeleti Flutter projesine aktar (`flutter create` + dosyaları kopyala).
2. `chat_service.dart` içindeki basit cevap mantığını test et.
3. Karakter seçim ekranını ve tema sistemini tamamla.
4. Kamera + ML Kit yüz algılamayı `home_screen.dart`'a entegre et. ✅ Tamamlandı
5. Ebeveyn kontrol panelini (PIN, süre limiti) bitir.
6. En son AI sohbet motorunu (LLM API veya yerel model) bağla. ✅ İskelet hazır

## Eklenen Modüller (bu turda)
- **Kişi tanıma**: `face_recognition_service.dart` + `person_enrollment_screen.dart`.
  TFLite tabanlı, tamamen cihaz üzerinde çalışır. Kurulum için
  `FACE_MODEL_SETUP.md` dosyasına bak — bir model dosyası eklemen gerekiyor.
- **AI sohbet motoru**: `ai_chat_engine.dart` (arayüz) +
  `remote_ai_chat_engine.dart` (örnek implementasyon). `ChatService`'e
  `aiEngine` parametresi vermezsen kural tabanlı moda düşer; API anahtarın
  olduğunda `home_screen.dart` içindeki yorum satırını açman yeterli.

Her adımda bana "şimdi X modülünü tam kod olarak yaz" dersen, o modülü ayrıntılı
ve çalışır şekilde üretirim — hepsini tek seferde değil, parça parça sağlam
ilerlemek çok daha az hataya yol açar.
