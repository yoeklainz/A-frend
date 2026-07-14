import 'package:speech_to_text/speech_to_text.dart';

/// Mikrofon ile Türkçe konuşmayı metne çevirir.
/// "İsmiyle çağırma" özelliği için son duyulan metni dışarıya bildirir,
/// üst katman (ChatService) bu metinde uyandırma kelimesini arar.
class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  Future<bool> initialize() async {
    return _speech.initialize(
      onError: (error) => print('STT hata: $error'),
      onStatus: (status) => print('STT durum: $status'),
    );
  }

  bool get isListening => _isListening;

  /// Sürekli dinleme başlatır. Her yeni sonuç [onResult] ile bildirilir.
  Future<void> startListening(void Function(String recognizedText) onResult) async {
    if (_isListening) return;
    _isListening = true;
    await _speech.listen(
      localeId: 'tr_TR',
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }
}
