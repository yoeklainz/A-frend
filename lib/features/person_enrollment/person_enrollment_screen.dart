import 'package:flutter/material.dart';
import '../../core/models/character.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/face_detection_service.dart';
import '../../core/services/face_recognition_service.dart';
import '../../core/services/database_service.dart';

/// Ebeveyn panelinden açılan, yeni bir aile üyesini (isim + yüz) sisteme
/// kaydeden ekran. Birden fazla kareden embedding ortalaması alarak daha
/// kararlı bir "kimlik vektörü" üretir.
///
/// Bu ekran SADECE ebeveyn kontrol paneli içinden, PIN doğrulamasından
/// sonra açılmalıdır — çocuğun kendi başına yeni profil ekleyebilmesi
/// istenmez.
class PersonEnrollmentScreen extends StatefulWidget {
  const PersonEnrollmentScreen({super.key});

  @override
  State<PersonEnrollmentScreen> createState() => _PersonEnrollmentScreenState();
}

class _PersonEnrollmentScreenState extends State<PersonEnrollmentScreen> {
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceService = FaceDetectionService();
  final FaceRecognitionService _recognitionService = FaceRecognitionService();
  final TextEditingController _nameController = TextEditingController();

  final List<List<double>> _capturedEmbeddings = [];
  static const int _requiredSamples = 5;
  bool _isCapturing = false;
  bool _cameraReady = false;
  int _ageYears = 8;
  bool _isParent = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await _cameraService.initializeFrontCamera();
      await _recognitionService.loadModel();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera veya model başlatılamadı: $e')),
        );
      }
    }
  }

  Future<void> _captureSample() async {
    if (!_cameraReady || _isCapturing) return;
    setState(() => _isCapturing = true);

    final sensorOrientation = _cameraService.controller!.description.sensorOrientation;
    bool sampleTaken = false;

    await _cameraService.startImageStream((image) async {
      if (sampleTaken) return;
      final result = await _faceService.analyzeFrame(image, sensorOrientation);
      if (result.faceDetected && result.rawFace != null) {
        sampleTaken = true;
        try {
          final embedding = _recognitionService.extractEmbedding(image, result.rawFace!);
          _capturedEmbeddings.add(embedding);
        } catch (_) {
          // Bu örnek başarısız oldu, kullanıcı tekrar deneyebilir.
        }
        await _cameraService.stopImageStream();
        if (mounted) setState(() => _isCapturing = false);
      }
    });
  }

  List<double> _averageEmbeddings() {
    final length = _capturedEmbeddings.first.length;
    final avg = List.filled(length, 0.0);
    for (final embedding in _capturedEmbeddings) {
      for (int i = 0; i < length; i++) {
        avg[i] += embedding[i] / _capturedEmbeddings.length;
      }
    }
    return avg;
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lütfen bir isim gir.')));
      return;
    }
    if (_capturedEmbeddings.length < _requiredSamples) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_requiredSamples yüz örneği gerekli, ${_capturedEmbeddings.length} alındı.')),
      );
      return;
    }

    final profile = UserProfile(
      name: _nameController.text.trim(),
      isParent: _isParent,
      ageYears: _ageYears,
      preferredCharacter: CharacterType.robot,
      faceEmbedding: _averageEmbeddings(),
    );

    await DatabaseService.instance.insertProfile(profile);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceService.dispose();
    _recognitionService.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _capturedEmbeddings.length / _requiredSamples;

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Aile Üyesi Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'İsim', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Yaş:'),
                Expanded(
                  child: Slider(
                    value: _ageYears.toDouble(),
                    min: 2,
                    max: 60,
                    divisions: 58,
                    label: '$_ageYears',
                    onChanged: (v) => setState(() => _ageYears = v.round()),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Bu kişi bir ebeveyn mi?'),
              value: _isParent,
              onChanged: (v) => setState(() => _isParent = v),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress.clamp(0, 1)),
            const SizedBox(height: 8),
            Text('${_capturedEmbeddings.length} / $_requiredSamples yüz örneği alındı'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_isCapturing ? 'Yüz aranıyor...' : 'Yüz Örneği Al'),
              onPressed: _cameraReady && !_isCapturing ? _captureSample : null,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _capturedEmbeddings.length >= _requiredSamples ? _saveProfile : null,
              child: const Text('Profili Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
