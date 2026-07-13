# Android İzinleri — AndroidManifest.xml'e eklenmesi gerekenler

`android/app/src/main/AndroidManifest.xml` içine, `<application>` etiketinden
ÖNCE aşağıdaki izinleri ekle:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />

<uses-feature android:name="android.hardware.camera" android:required="true" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

## Çalışma zamanı izinleri (runtime permissions)
Android 6.0+ (API 23+) için kamera ve mikrofon izinlerini kod içinde de
istemen gerekir. Bunun için `permission_handler` paketini ekle:

```yaml
dependencies:
  permission_handler: ^11.3.1
```

Örnek kullanım (uygulama açılışında, karakter ekranına geçmeden önce):

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestChildSafetyPermissions() async {
  final statuses = await [
    Permission.camera,
    Permission.microphone,
  ].request();

  return statuses.values.every((status) => status.isGranted);
}
```

## Önemli: Ebeveyn onayı akışı
Bu izin isteğini çocuğun göreceği ekrandan DEĞİL, ebeveynin PIN ile
doğrulandığı ilk kurulum ekranından tetikle. Böylece kamera/mikrofon
erişimi çocuğun tek başına açıp kapatabileceği bir şey olmaz.

## ML Kit modelleri hakkında not
`google_mlkit_face_detection` ve `google_mlkit_pose_detection` paketleri
gerekli modelleri ya uygulamayla birlikte paketler ya da ilk çalıştırmada
Google Play Services aracılığıyla indirir (cihaz ve paket sürümüne göre
değişir). Tablet internete hiç bağlanmayacaksa, ilgili paketin
dokümantasyonunda "bundled model" (uygulamaya gömülü model) seçeneğini
kullanman gerekir — bu, APK boyutunu artırır ama tamamen çevrimdışı çalışır.
