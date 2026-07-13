# Kişi Tanıma Modeli Kurulumu

`FaceRecognitionService`, `assets/models/face_recognition.tflite` adında bir
model dosyası bekler. Bu dosya boyut nedeniyle bu projeye dahil edilmedi —
kendin eklemen gerekiyor. Adımlar:

## 1) Model dosyasını edin
Ücretsiz, açık kaynak seçenekler:
- **MobileFaceNet** (TFLite) — küçük (~5 MB), tabletler için hızlı, 192
  boyutlu embedding üretir (bu projedeki kod bunu varsayıyor).
- **FaceNet** (TFLite dönüşümü) — daha büyük ama daha isabetli.

TensorFlow Hub, Kaggle veya GitHub üzerinde "mobilefacenet tflite" araması
yaparak MIT/Apache lisanslı bir sürüm bulabilirsin. Kullanmadan önce
lisansını kontrol et.

## 2) Projeye ekle
```
ai_buddy_kids/
  assets/
    models/
      face_recognition.tflite   <-- buraya koy
```

`pubspec.yaml` içinde `assets/models/` zaten tanımlı, ekstra bir şey
yapmana gerek yok.

## 3) Giriş/çıkış boyutlarını doğrula
Kullandığın modelin giriş boyutu 112x112x3 ve çıkışı 192 boyutlu bir
vektör DEĞİLSE, `face_recognition_service.dart` içindeki `_inputSize` ve
`_embeddingSize` sabitlerini modeline göre güncellemen gerekir. Model
dosyasını bir araç (ör. Netron - netron.app) ile açıp giriş/çıkış
şekillerini kontrol edebilirsin.

## 4) Eşik değerini kalibre et
`_matchThreshold = 0.55` başlangıç değeri MobileFaceNet için makul bir
tahmindir ama gerçek kullanımda ayarlaman gerekebilir:
- Çok fazla "yanlış tanıma" oluyorsa (biri başkası sanılıyor) → eşiği artır.
- Tanınan kişi sık sık "tanınmadı" oluyorsa → eşiği azalt.

## Model olmadan ne olur?
`PresenceManager.start()` model yüklenemezse kişi tanımayı otomatik
olarak devre dışı bırakır; yüz ifadesi algılama, el sallama ve sesli
sohbet gibi diğer tüm özellikler normal çalışmaya devam eder.
