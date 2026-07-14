import 'dart:math';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/user_profile.dart';

/// Yüzden 192 boyutlu bir "kimlik vektörü" (embedding) çıkarır ve bunu
/// kayıtlı aile profilleriyle karşılaştırarak "bu kim?" sorusunu cevaplar.
///
/// Kullanılan yaklaşım (MobileFaceNet benzeri bir TFLite modeli):
/// 1. ML Kit'in bulduğu yüz kutusuyla (bounding box) kamera karesinden
///    yüz bölgesi kırpılır.
/// 2. 112x112'ye yeniden boyutlandırılır ve normalize edilir.
/// 3. TFLite modeliyle 192 boyutlu bir vektöre (embedding) dönüştürülür.
/// 4. Bu vektör, kayıtlı her profilin vektörüyle kosinüs benzerliğine göre
///    karşılaştırılır; en yüksek benzerlik eşik değerini geçiyorsa o kişi
///    tanınmış sayılır.
///
/// NOT: `assets/models/face_recognition.tflite` modelini projene EKLEMEN
/// gerekiyor. Ücretsiz, açık kaynak seçenekler: "MobileFaceNet" veya
/// "FaceNet" TFLite dönüşümleri (TensorFlow Hub / GitHub'da bulunabilir).
/// Model olmadan bu servis çalışmaz; enrollFace/identify çağrıları
/// StateError fırlatır.
class FaceRecognitionService {
  static const int _inputSize = 112;
  static const int _embeddingSize = 192;
  static const double _matchThreshold = 0.55; // kosinüs benzerliği eşiği

  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/face_recognition.tflite');
  }

  bool get isReady => _interpreter != null;

  /// Kamera karesinden, verilen yüz kutusunu kırpıp embedding üretir.
  List<double> extractEmbedding(CameraImage image, Face face) {
    if (_interpreter == null) {
      throw StateError(
        'Yüz tanıma modeli yüklenmedi. Önce loadModel() çağrılmalı ve '
        'assets/models/face_recognition.tflite dosyasının eklenmiş olması gerekir.',
      );
    }

    final rgbImage = _cameraImageToImage(image);
    final box = face.boundingBox;

    // Kutunun görüntü sınırları dışına taşmasını engelle.
    final left = box.left.clamp(0, rgbImage.width - 1).toInt();
    final top = box.top.clamp(0, rgbImage.height - 1).toInt();
    final width = (box.width).clamp(1, rgbImage.width - left).toInt();
    final height = (box.height).clamp(1, rgbImage.height - top).toInt();

    final faceCrop = img.copyCrop(rgbImage, x: left, y: top, width: width, height: height);
    final resized = img.copyResize(faceCrop, width: _inputSize, height: _inputSize);

    // Modelin beklediği [1, 112, 112, 3] float32 girişini hazırla,
    // piksel değerlerini [-1, 1] aralığına normalize et.
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r / 127.5) - 1.0,
            (pixel.g / 127.5) - 1.0,
            (pixel.b / 127.5) - 1.0,
          ];
        }),
      ),
    );

    final output = List.generate(1, (_) => List.filled(_embeddingSize, 0.0));
    _interpreter!.run(input, output);

    return output.first;
  }

  /// Kayıtlı profiller arasından en çok benzeyeni bulur.
  /// Eşik değerini geçen bir eşleşme yoksa null döner ("tanınmayan kişi").
  UserProfile? matchProfile(List<double> embedding, List<UserProfile> profiles) {
    UserProfile? bestMatch;
    double bestScore = -1;

    for (final profile in profiles) {
      if (profile.faceEmbedding == null) continue;
      final score = _cosineSimilarity(embedding, profile.faceEmbedding!);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = profile;
      }
    }

    if (bestMatch != null && bestScore >= _matchThreshold) {
      return bestMatch;
    }
    return null;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  /// Android kamera akışından gelen NV21 formatındaki kareyi `image`
  /// paketinin anlayacağı bir img.Image'a çevirir.
  ///
  /// PERFORMANS NOTU: Bu dönüşüm piksel piksel yapıldığı için görece
  /// yavaştır. Kişi tanımayı her karede değil, yüz zaten algılandığında
  /// ve birkaç saniyede bir çalıştırman (bkz. PresenceManager'daki
  /// örnekleme mantığı) önerilir.
  img.Image _cameraImageToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];
    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final outImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        // YUV -> RGB dönüşüm formülü.
        final r = (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt();

        outImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return outImage;
  }

  void dispose() {
    _interpreter?.close();
  }
}
