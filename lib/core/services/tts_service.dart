import 'package:flutter_tts/flutter_tts.dart';
import '../models/character.dart';

/// Karakterin metni sesli olarak söylemesini sağlar.
/// Her karakterin kendi konuşma hızı/tonu Character modelinden gelir,
/// böylece "Robo" robotik, "Minnoş" daha tiz konuşur gibi bir his verilir.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _ensureInit() async {
    if (_isInitialized) return;
    await _tts.setLanguage('tr-TR');
    await _tts.setVolume(1.0);
    _isInitialized = true;
  }

  /// Verilen karakterin ses profiline göre metni seslendirir.
  Future<void> speakAs(Character character, String text) async {
    await _ensureInit();
    await _tts.setSpeechRate(character.speechRate);
    await _tts.setPitch(character.speechPitch);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
