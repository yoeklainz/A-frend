# Tabletinden APK Alma — Adım Adım (Bilgisayar Gerektirmez)

Bu proje artık GitHub Actions ile otomatik APK derlemeye hazır
(`.github/workflows/build.yml`). Sadece kodu GitHub'a yükleyip
sonucu indirmen yeterli.

## 1) GitHub hesabı aç
https://github.com adresine tabletinin tarayıcısından git, ücretsiz
hesap oluştur (zaten varsa atla).

## 2) Yeni bir repo oluştur
- Sağ üstteki "+" → "New repository"
- İsim: `ai-buddy-kids` (istediğin ismi verebilirsin)
- "Public" veya "Private" fark etmez (Private de ücretsiz Actions dakikası alır)
- "Create repository"

## 3) Proje dosyalarını yükle
Repo sayfasında "uploading an existing file" linkine tıkla, sana
verdiğim tüm `ai_buddy_kids` klasörünün İÇİNDEKİ dosya ve klasörleri
(pubspec.yaml, lib/, android/, assets/, .github/ dahil) sürükleyip
bırak. Tarayıcı klasör sürüklemeyi desteklemiyorsa, dosyaları ZIP'leyip
GitHub Desktop mobil uygulaması ya da "GitHub Mobile" app üzerinden de
yükleyebilirsin — ama en kolayı masaüstü tarayıcı modunda (tabletin
tarayıcısında "masaüstü sitesini iste" seçeneği) GitHub'ın web
arayüzünü kullanmak.

**Önemli:** `.github` klasörü gizli bir klasör gibi görünebilir,
tarayıcıdan yüklerken bunun da dahil olduğundan emin ol — APK derlemesini
tetikleyen dosya orada.

## 4) Derlemenin başlamasını bekle
Dosyaları yükleyip "Commit changes" dediğin an derleme otomatik
başlar. Repo sayfasında üstteki **"Actions"** sekmesine gir, "APK
Derle" iş akışının çalıştığını göreceksin (yeşil tik = başarılı,
kırmızı X = hata, genelde 5-10 dakika sürer).

## 5) APK'yı indir
Derleme bitince, o çalışmanın (workflow run) sayfasına gir, en altta
**"Artifacts"** bölümünde `ai-buddy-kids-apk` göreceksin — buna
tıklayınca bir ZIP iner, içinde `app-release.apk` var. Bu ZIP'i açıp
APK'yı tabletine kur (kurulum sırasında "bilinmeyen kaynaklardan
yükleme" iznini açman gerekebilir — Android ayarlarında karşına çıkar).

## Derleme hata verirse
En sık nedenler:
1. `assets/models/face_recognition.tflite` eksik → kişi tanıma çalışmaz
   ama APK yine de derlenir (kod bunu graceful şekilde atlıyor).
2. Bir dosya eksik yüklenmiş olabilir → "Actions" sekmesindeki kırmızı
   çalışmaya tıkla, hata logunu oku; genelde hangi dosyanın eksik
   olduğunu satır satır gösterir.
3. Paket sürüm uyuşmazlığı → bana hata logunun ilgili kısmını
   yapıştırırsan `pubspec.yaml`'daki sürümleri düzeltebilirim.

## Sonraki güncellemeler
Kodda değişiklik yaptığımda sana yeni dosyalar vereceğim; onları aynı
repoya tekrar yükleyip "Commit changes" dediğinde APK otomatik olarak
yeniden derlenir — her seferinde bu adımları baştan yapmana gerek yok.
