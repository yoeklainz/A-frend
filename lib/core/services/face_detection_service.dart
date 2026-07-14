import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/character.dart';

/// Kameradan gelen görüntüde yüz olup olmadığını, gülümseme/göz açıklığı
/// gibi temel ifadeleri tespit eder ve bunları EmotionState'e çevirir.
///
/// ML Kit yalnızca "gülümseme olasılığı" ve "gözlerin açık olma olasılığı"
/// veriyor; "üzgün" veya "şaşkın" gibi ifadeler bunlardan basit kurallarla
/// türetiliyor. Daha hassas duygu tanıma istersen özel eğitilmiş bir
/// TensorFlow Lite modeli (ör. FER — Facial Expression Recognition) ekleyip
/// bu sınıfın içini değiştirebilirsin; dışarıya açılan arayüz aynı kalır.
class FaceDetectionResult {
  final bool faceDetected;
  final EmotionState emotion;
  final double smilingProbability;
  // Kişi tanıma servisinin yüzü kırpıp embedding çıkarabilmesi için
  // ham ML Kit Face nesnesi (bounding box vb.) burada taşınır.
  // UI katmanları bunu kullanmaz, sadece FaceRecognitionService kullanır.
  final Face? rawFace;

  const FaceDetectionResult({
    required this.faceDetected,
    required this.emotion,
    required this.smilingProbability,
    this.rawFace,
  });

  static const notDetected = FaceDetectionResult(
    faceDetected: false,
    emotion: EmotionState.curious,
    smilingProbability: 0,
  );
}

class FaceDetectionService {
  late final FaceDetector _detector;

  FaceDetectionService() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // gülümseme / göz açıklığı olasılıkları için şart
        enableTracking: true, // kullanıcı gidip geldiğinde aynı yüzü takip etmek için
        performanceMode: FaceDetectorMode.fast, // canlı akış için hız önceliği
      ),
    );
  }

  /// Tek bir kamera karesini analiz eder.
  /// [sensorOrientation] cihazın kamera sensör açısıdır (CameraDescription.sensorOrientation).
  Future<FaceDetectionResult> analyzeFrame(
    CameraImage image,
    int sensorOrientation,
  ) async {
    final inputImage = _toInputImage(image, sensorOrientation);
    if (inputImage == null) return FaceDetectionResult.notDetected;

    final faces = await _detector.processImage(inputImage);
    if (faces.isEmpty) return FaceDetectionResult.notDetected;

    final face = faces.first;
    final smileProb = face.smilingProbability ?? 0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;

    final emotion = _inferEmotion(smileProb, avgEyeOpen);

    return FaceDetectionResult(
      faceDetected: true,
      emotion: emotion,
      smilingProbability: smileProb,
      rawFace: face,
    );
  }

  /// Basit kural tabanlı duygu çıkarımı. Örnek eşik değerleri; gerçek
  /// kullanıcı testleriyle ayarlaman önerilir.
  EmotionState _inferEmotion(double smileProb, double eyeOpenProb) {
    if (smileProb > 0.75) return EmotionState.excited;
    if (smileProb > 0.4) return EmotionState.happy;
    if (eyeOpenProb < 0.25) return EmotionState.sleepy;
    if (smileProb < 0.1 && eyeOpenProb > 0.8) return EmotionState.surprised;
    return EmotionState.curious;
  }

  InputImage? _toInputImage(CameraImage image, int sensorOrientation) {
    // NV21 formatı (Android) için tek plane birleştirme.
    // iOS'a genişletirsen BGRA8888 formatı için ayrı bir dallanma eklenmeli.
    if (!Platform.isAndroid) return null;

    final bytes = image.planes.first.bytes;
    final imageSize = ui.Size(image.width.toDouble(), image.height.toDouble());

    final rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Future<void> dispose() => _detector.close();
}
