import 'dart:async';
import 'package:camera/camera.dart';
import '../models/character.dart';
import '../models/user_profile.dart';
import 'camera_service.dart';
import 'face_detection_service.dart';
import 'face_recognition_service.dart';
import 'wave_detection_service.dart';

/// Karakter ekranının ihtiyaç duyduğu tüm görsel algılamayı tek bir
/// yerden yönetir: kamera akışı, yüz/ifade tanıma, kişi tanıma,
/// el sallama tespiti ve "kullanıcı gitti / geri geldi" bildirimleri.
///
/// UI katmanı (HomeScreen) sadece bu sınıfın callback'lerini dinler,
/// ML Kit / camera detaylarıyla hiç uğraşmaz.
class PresenceManager {
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceService = FaceDetectionService();
  final WaveDetectionService _waveService = WaveDetectionService();
  final FaceRecognitionService _recognitionService = FaceRecognitionService();

  // Kayıtlı aile profilleri — start() çağrılmadan önce dışarıdan set edilir.
  List<UserProfile> knownProfiles = [];

  int _frameCounter = 0;
  bool _isProcessingFrame = false;
  bool _userPresent = false;
  DateTime? _lastAbsenceCheck;
  UserProfile? _currentIdentifiedProfile;
  DateTime? _lastRecognitionAttempt;

  void Function(EmotionState emotion, double smileProbability)? onEmotionChanged;
  void Function()? onWaveDetected;
  void Function()? onUserLeft;
  void Function()? onUserReturned;
  // profile null ise: yüz algılandı ama kayıtlı profillerden hiçbiriyle eşleşmedi.
  void Function(UserProfile? profile)? onPersonIdentified;

  Future<void> start({bool enableRecognition = true}) async {
    await _cameraService.initializeFrontCamera();
    final sensorOrientation = _cameraService.controller!.description.sensorOrientation;

    if (enableRecognition) {
      try {
        await _recognitionService.loadModel();
      } catch (e) {
        // Model dosyası eklenmemişse kişi tanıma sessizce devre dışı kalır;
        // diğer tüm özellikler (ifade, el sallama) çalışmaya devam eder.
        enableRecognition = false;
      }
    }

    await _cameraService.startImageStream((CameraImage image) async {
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;
      _frameCounter++;

      try {
        final faceResult = await _faceService.analyzeFrame(image, sensorOrientation);
        _handlePresence(faceResult.faceDetected);

        if (faceResult.faceDetected) {
          onEmotionChanged?.call(faceResult.emotion, faceResult.smilingProbability);

          if (enableRecognition && faceResult.rawFace != null) {
            _maybeRunRecognition(image, faceResult.rawFace!);
          }
        } else {
          _currentIdentifiedProfile = null;
        }

        if (_frameCounter % 2 == 0) {
          final waved = await _waveService.analyzeFrame(image, sensorOrientation);
          if (waved) onWaveDetected?.call();
        }
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  /// Kişi tanımayı her karede değil, ~1.5 saniyede bir çalıştırır —
  /// hem performans için hem de sonucun gereksiz yere "titremesini"
  /// (aynı kişi için sürekli farklı sonuç dönmesini) azaltmak için.
  void _maybeRunRecognition(CameraImage image, dynamic rawFace) {
    final now = DateTime.now();
    if (_lastRecognitionAttempt != null &&
        now.difference(_lastRecognitionAttempt!) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastRecognitionAttempt = now;

    try {
      final embedding = _recognitionService.extractEmbedding(image, rawFace);
      final matched = _recognitionService.matchProfile(embedding, knownProfiles);

      final changed = matched?.id != _currentIdentifiedProfile?.id;
      _currentIdentifiedProfile = matched;
      if (changed) {
        onPersonIdentified?.call(matched);
      }
    } catch (e) {
      // Kırpma/çözünürlük kaynaklı ara sıra hatalar sessizce atlanır;
      // bir sonraki karede tekrar denenir.
    }
  }

  /// Yüz belirli bir süre (3 sn) görünmezse "kullanıcı gitti",
  /// tekrar görünürse "kullanıcı döndü" olarak bildirir. Ani, tek
  /// karelik kayıplarda (ör. göz kırpma sırasında yanlış negatif)
  /// yanlış tetiklenmeyi önlemek için zaman eşiği kullanılır.
  void _handlePresence(bool faceDetectedNow) {
    final now = DateTime.now();

    if (faceDetectedNow) {
      _lastAbsenceCheck = null;
      if (!_userPresent) {
        _userPresent = true;
        onUserReturned?.call();
      }
      return;
    }

    _lastAbsenceCheck ??= now;
    final absentDuration = now.difference(_lastAbsenceCheck!);
    if (_userPresent && absentDuration > const Duration(seconds: 3)) {
      _userPresent = false;
      onUserLeft?.call();
    }
  }

  CameraController? get cameraController => _cameraService.controller;

  Future<void> dispose() async {
    await _cameraService.dispose();
    await _faceService.dispose();
    await _waveService.dispose();
    _recognitionService.dispose();
  }
}

