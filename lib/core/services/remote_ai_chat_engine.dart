import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_chat_engine.dart';

/// Bir LLM sağlayıcısının REST API'sine bağlanan somut implementasyon.
///
/// ÖNEMLİ — "ücretsiz" konusunda dürüst olalım: gerçekten sınırsız,
/// ücretsiz bir bulut LLM yok. Seçeneklerin:
///   1) Bir sağlayıcının ücretsiz/deneme kotasını kullanmak (çoğu sağlayıcı
///      sınırlı ücretsiz istek hakkı verir — güncel koşulları sağlayıcının
///      kendi sitesinden kontrol et).
///   2) Cihaz üzerinde çalışan küçük bir açık kaynak model (tablette
///      performansı sınırlı olur, ekstra kurulum gerektirir).
///   3) Şu anki kural tabanlı sistemi (ChatService içindeki fallback)
///      geliştirerek daha zengin bir "sahte AI" hissi vermek — tamamen
///      ücretsiz ve internetsiz çalışır.
///
/// Bu sınıf, hangi sağlayıcıyı seçersen seç aynı kalacak şekilde
/// tasarlandı: sadece [_endpoint], [_apiKey] ve [_buildRequestBody] /
/// [_parseResponse] metodlarını kendi sağlayıcına göre güncellemen yeterli.
/// Aşağıdaki örnek Anthropic Claude API formatına göre yazılmıştır.
class RemoteAiChatEngine implements AiChatEngine {
  final String _apiKey;
  final Uri _endpoint;

  /// API anahtarını asla kaynak kodun içine SABİT olarak yazma — bir
  /// yapılandırma dosyasından, ortam değişkeninden veya güvenli bir
  /// depolamadan oku. Burada parametre olarak dışarıdan alınıyor.
  RemoteAiChatEngine({required String apiKey, Uri? endpoint})
      : _apiKey = apiKey,
        _endpoint = endpoint ?? Uri.parse('https://api.anthropic.com/v1/messages');

  @override
  Future<String> generateReply({
    required String systemPrompt,
    required String userMessage,
    required List<ChatTurn> recentHistory,
  }) async {
    final response = await http
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode(_buildRequestBody(systemPrompt, userMessage, recentHistory)),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('AI API hatası: ${response.statusCode} ${response.body}');
    }

    return _parseResponse(response.body);
  }

  Map<String, dynamic> _buildRequestBody(
    String systemPrompt,
    String userMessage,
    List<ChatTurn> history,
  ) {
    return {
      'model': 'claude-haiku-4-5-20251001', // düşük maliyetli, hızlı model
      'max_tokens': 300, // çocuk sohbeti için kısa cevaplar yeterli
      'system': systemPrompt,
      'messages': [
        ...history.map((t) => {'role': t.role, 'content': t.content}),
        {'role': 'user', 'content': userMessage},
      ],
    };
  }

  String _parseResponse(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>;
    final textBlock = content.firstWhere(
      (block) => block['type'] == 'text',
      orElse: () => null,
    );
    if (textBlock == null) throw Exception('AI cevabı ayrıştırılamadı.');
    return textBlock['text'] as String;
  }
}
