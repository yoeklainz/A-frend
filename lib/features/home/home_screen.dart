import 'package:flutter/material.dart';
import '../../core/models/character.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/stt_service.dart';
import '../../core/services/presence_manager.dart';
import '../../core/services/database_service.dart';
import 'widgets/character_avatar.dart';
// import '../../core/services/remote_ai_chat_engine.dart'; // gerçek AI'ı aktif etmek için bkz. aşağıdaki not

/// Tam ekran animasyonlu karakterin gösterildiği ana ekran.
/// Mikrofon butonuna basınca dinlemeye başlar, cevabı hem yazı hem
/// sesli olarak (TTS) verir.
///
/// Kamera tabanlı algılama PresenceManager üzerinden yönetilir:
/// - Yüz ifadesine göre karakterin duygu durumu güncellenir.
/// - El sallama algılandığında karakter karşılık verir.
/// - Kullanıcı kadraj dışına çıkıp geri geldiğinde selamlama tekrarlanır.
/// - Kayıtlı aile üyelerinden biri tanınırsa sohbet ona özel hitap eder.
class HomeScreen extends StatefulWidget {
  final Character character;
  const HomeScreen({super.key, required this.character});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // AI motorunu gerçek bir API'ye bağlamak için:
  //   final ChatService _chatService = ChatService(
  //     aiEngine: RemoteAiChatEngine(apiKey: 'BURAYA_KENDI_ANAHTARIN'),
  //   );
  // API anahtarı olmadan aşağıdaki satır kural tabanlı moda düşer —
  // uygulama internetsiz de tam çalışır.
  final ChatService _chatService = ChatService();
  final TtsService _ttsService = TtsService();
  final SttService _sttService = SttService();
  final PresenceManager _presenceManager = PresenceManager();

  String _lastReply = '';
  bool _isListening = false;
  EmotionState _currentEmotion = EmotionState.curious;
  bool _cameraReady = false;
  UserProfile? _identifiedProfile;

  @override
  void initState() {
    super.initState();
    _sttService.initialize();
    _initCamera();
    // Karakter ekrana gelir gelmez selamlar.
    _ttsService.speakAs(widget.character, widget.character.greeting);
    _lastReply = widget.character.greeting;
  }

  Future<void> _initCamera() async {
    // NOT: Kamera izni bu noktadan önce alınmış olmalı. Üretim kodunda
    // permission_handler ile izin kontrolü/isteme akışını buraya ekle;
    // izin reddedilirse kamera özellikleri sessizce devre dışı kalmalı
    // (sohbet/TTS/STT özellikleri kamerasız da tam çalışmaya devam eder).
    try {
      // Kişi tanıma için kayıtlı profilleri yerel veritabanından yükle.
      final profiles = await DatabaseService.instance.getAllProfiles();
      _presenceManager.knownProfiles = profiles;

      _presenceManager.onEmotionChanged = (emotion, smileProb) {
        if (mounted) setState(() => _currentEmotion = emotion);
      };
      _presenceManager.onWaveDetected = () {
        _ttsService.speakAs(widget.character, 'Merhaba! Bana el salladın, çok tatlısın!');
      };
      _presenceManager.onUserLeft = () {
        // Kullanıcı kadraj dışına çıktı — karakter sessizce bekler,
        // istersen burada "uykulu" animasyon durumuna geçebilirsin.
        if (mounted) setState(() => _currentEmotion = EmotionState.sleepy);
      };
      _presenceManager.onUserReturned = () {
        _ttsService.speakAs(widget.character, 'Tekrar hoş geldin!');
      };
      _presenceManager.onPersonIdentified = (profile) {
        if (!mounted) return;
        setState(() => _identifiedProfile = profile);
        if (profile != null) {
          _ttsService.speakAs(widget.character, 'Merhaba ${profile.name}! Seni tanıdım.');
        }
      };

      await _presenceManager.start();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      // Kamera başlatılamadıysa (izin yok, donanım yok vb.) uygulama
      // sesli sohbet moduyla çalışmaya devam eder.
      debugPrint('Kamera başlatılamadı: $e');
    }
  }

  Future<void> _handleUserSpeech(String recognizedText) async {
    if (recognizedText.trim().isEmpty) return;

    final reply = await _chatService.generateReply(
      userMessage: recognizedText,
      character: widget.character,
      ageYears: _identifiedProfile?.ageYears ?? 7,
      personName: _identifiedProfile?.name,
    );

    setState(() => _lastReply = reply);
    await _ttsService.speakAs(widget.character, reply);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _sttService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _sttService.startListening((text) {
        _handleUserSpeech(text);
        setState(() => _isListening = false);
      });
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _sttService.stopListening();
    _presenceManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_identifiedProfile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  avatar: const Icon(Icons.face, size: 18),
                  label: Text('Tanındı: ${_identifiedProfile!.name}'),
                ),
              ),
            // Karakter, dışarıdan animasyon dosyası gerektirmeyen, kod
            // içinde çizilen CharacterAvatar ile gösteriliyor (bkz.
            // widgets/character_avatar.dart). Gerçek Lottie animasyonu
            // eklemek istersen bu widget'ı değiştirmen yeterli.
            Expanded(
              flex: 3,
              child: Center(
                child: CharacterAvatar(character: widget.character, emotion: _currentEmotion),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _lastReply,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: FloatingActionButton.large(
                onPressed: _toggleListening,
                backgroundColor:
                    _isListening ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
