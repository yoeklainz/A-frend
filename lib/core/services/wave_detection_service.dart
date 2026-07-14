import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// El sallama hareketini bilek noktasının (wrist landmark) yatay eksende
/// tekrar eden salınımını izleyerek tespit eder.
///
/// Yaklaşım: Son N karedeki bilek x-konumunu bir kuyrukta tutar; kuyrukta
/// yön değişimi (soldan sağa, sağdan sola) belirli bir sayının üzerinde ve
/// kısa bir zaman aralığında gerçekleşmişse "el sallıyor" kabul eder.
/// Bu, tam bir hareket sınıflandırma modeli kadar hassas değildir ama
/// ekstra model indirmeden hızlı ve yeterince güvenilir çalışır.
class WaveDetectionService {
  late final PoseDetector _detector;
  final List<double> _wristXHistory = [];
  final int _historyWindow = 12; // yaklaşık son ~1 saniyelik kare geçmişi
  DateTime? _lastWaveDetectedAt;

  WaveDetectionService() {
    _detector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
  }

  /// Tek bir kareyi analiz eder, el sallama tespit edilirse true döner.
  /// Ardışık tetiklemeleri önlemek için 2 saniyelik "soğuma süresi" uygular.
  Future<bool> analyzeFrame(CameraImage image, int sensorOrientation) async {
    final inputImage = _toInputImage(image, sensorOrientation);
    if (inputImage == null) return false;

    final poses = await _detector.processImage(inputImage);
    if (poses.isEmpty) return false;

    final pose = poses.first;
    // Sağ bilek yoksa sol bileği dene (kullanıcı hangi eliyle sallıyorsa).
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist] ??
        pose.landmarks[PoseLandmarkType.leftWrist];
    if (wrist == null || wrist.likelihood < 0.6) return false;

    _wristXHistory.add(wrist.x);
    if (_wristXHistory.length > _historyWindow) {
      _wristXHistory.removeAt(0);
    }

    if (_wristXHistory.length < _historyWindow) return false;

    final directionChanges = _countDirectionChanges(_wristXHistory);
    final now = DateTime.now();
    final cooledDown = _lastWaveDetectedAt == null ||
        now.difference(_lastWaveDetectedAt!) > const Duration(seconds: 2);

    // Kısa pencerede en az 3 yön değişimi = sağa-sola tekrar eden hareket.
    if (directionChanges >= 3 && cooledDown) {
      _lastWaveDetectedAt = now;
      _wristXHistory.clear();
      return true;
    }
    return false;
  }

  int _countDirectionChanges(List<double> values) {
    int changes = 0;
    for (int i = 2; i < values.length; i++) {
      final prevDelta = values[i - 1] - values[i - 2];
      final currDelta = values[i] - values[i - 1];
      // Yön değişimi + hareketin çok küçük (gürültü) olmaması.
      if (prevDelta.sign != currDelta.sign && currDelta.abs() > 5) {
        changes++;
      }
    }
    return changes;
  }

  InputImage? _toInputImage(CameraImage image, int sensorOrientation) {
    if (!Platform.isAndroid) return null;

    final bytes = image.planes.first.bytes;
    final imageSize = ui.Size(image.width.toDouble(), image.height.toDouble());
    final rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Future<void> dispose() => _detector.close();
}
