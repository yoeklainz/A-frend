import 'package:camera/camera.dart';

/// Ön kamerayı başlatan ve görüntü akışını (image stream) dışarıya
/// açan servis. FaceDetectionService bu akışı dinleyerek yüz analizi yapar.
class CameraService {
  CameraController? _controller;
  bool _isStreaming = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Cihazdaki ön kamerayı bulup başlatır.
  /// Not: Bu çağrıdan önce kamera izni alınmış olmalıdır
  /// (permission_handler veya camera paketinin kendi izin akışıyla).
  Future<void> initializeFrontCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium, // Yüz algılama için orta çözünürlük yeterli ve daha performanslı
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // ML Kit Android için uygun format
    );

    await _controller!.initialize();
  }

  /// Her karede [onImage] callback'ini çağırarak canlı analiz akışı başlatır.
  Future<void> startImageStream(void Function(CameraImage image) onImage) async {
    if (_controller == null || !_controller!.value.isInitialized || _isStreaming) return;
    _isStreaming = true;
    await _controller!.startImageStream(onImage);
  }

  Future<void> stopImageStream() async {
    if (_controller != null && _isStreaming) {
      await _controller!.stopImageStream();
      _isStreaming = false;
    }
  }

  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
