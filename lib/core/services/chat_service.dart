import '../models/character.dart';
import 'ai_chat_engine.dart';

/// Sohbet mantığının merkezi noktası. Eğer dışarıdan bir [AiChatEngine]
/// verilmişse (ör. RemoteAiChatEngine) gerçek bir AI modelinden cevap
/// almayı dener; model başarısız olursa (internet yok, API hatası vb.)
/// otomatik olarak kural tabanlı basit cevaplara geri döner — böylece
/// uygulama internetsiz ortamda da (tablet dışarıdayken, API kotası
/// bittiğinde vb.) çalışmaya devam eder.
///
/// Güvenlik filtresi HEM kullanıcı mesajına HEM AI'dan gelen cevaba
/// uygulanır — gerçek bir LLM'in bazen beklenmedik şeyler söyleyebileceği
/// unutulmamalı, bu yüzden çıktı seviyesinde filtre şart.
class ChatService {
  final AiChatEngine? _aiEngine;
  final List<ChatTurn> _history = [];
  static const int _maxHistoryTurns = 6; // bağlamı kısa tut, hem hız hem gizlilik için

  ChatService({AiChatEngine? aiEngine}) : _aiEngine = aiEngine;

  // Basit, genişletilebilir uygunsuz kelime listesi.
  // Gerçek üründe bu listeyi ayrı bir yapılandırma dosyasından/CMS'den
  // yönetmen ve düzenli güncellemen önerilir.
  static const List<String> _blockedTerms = [
    // örnek: 'kötü_kelime1', 'kötü_kelime2'
  ];

  bool _containsBlockedContent(String text) {
    final lower = text.toLowerCase();
    return _blockedTerms.any((term) => lower.contains(term));
  }

  /// Karakter, yaş ve (varsa) tanınan kişinin ismine göre AI modeline
  /// verilecek sistem talimatını oluşturur. Bu, hem karakterin kişiliğini
  /// hem de ÇOCUK GÜVENLİĞİ kurallarını modele açıkça bildirir.
  String _buildSystemPrompt({
    required Character character,
    required int ageYears,
    String? personName,
  }) {
    final nameClause = personName != null ? 'Konuştuğun çocuğun adı $personName.' : '';
    return '''
Sen "${character.displayName}" adında, çocuklar için tasarlanmış dostane bir
yapay zeka arkadaşsın. $nameClause Karşındaki çocuk $ageYears yaşında.

KURALLAR (asla çiğneme):
- Sadece Türkçe, basit ve yaşa uygun cümleler kullan.
- Şiddet, korku, cinsellik, küfür veya yetişkinlere özgü konulara asla girme.
- Kişisel bilgi (adres, telefon, okul adı gibi) isteme.
- Cevapların kısa olsun (2-3 cümle), sıcak ve eğlenceli bir ton kullan.
- Uygunsuz bir şey sorulursa nazikçe konuyu değiştir, asla azarlama.
''';
  }

  /// Ana giriş noktası: kullanıcı mesajını alır, karaktere uygun bir
  /// cevap üretir. [character] cevabın tonunu, [ageYears] karmaşıklığını,
  /// [personName] varsa tanınan kişiye özel hitabı belirler.
  Future<String> generateReply({
    required String userMessage,
    required Character character,
    required int ageYears,
    String? personName,
  }) async {
    if (_containsBlockedContent(userMessage)) {
      return 'Bu konu hakkında konuşamam, hadi başka bir şey konuşalım! '
          'Örneğin bir hikaye dinlemek ister misin?';
    }

    String reply;
    if (_aiEngine != null) {
      try {
        final systemPrompt = _buildSystemPrompt(
          character: character,
          ageYears: ageYears,
          personName: personName,
        );
        reply = await _aiEngine.generateReply(
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          recentHistory: _history,
        );
        _pushHistory(userMessage, reply);
      } catch (e) {
        // AI motoru başarısız oldu (internet yok, kota bitti vb.) —
        // sessizce kural tabanlı yanıta düş.
        reply = _simpleRuleBasedReply(userMessage, character);
      }
    } else {
      reply = _simpleRuleBasedReply(userMessage, character);
    }

    if (_containsBlockedContent(reply)) {
      return 'Hadi başka bir şey konuşalım, ben senin için bir bilmece '
          'hazırlayabilirim!';
    }

    return reply;
  }

  void _pushHistory(String userMessage, String reply) {
    _history.add(ChatTurn(role: 'user', content: userMessage));
    _history.add(ChatTurn(role: 'assistant', content: reply));
    while (_history.length > _maxHistoryTurns * 2) {
      _history.removeAt(0);
    }
  }

  String _simpleRuleBasedReply(String message, Character character) {
    final lower = message.toLowerCase();

    if (lower.contains('merhaba') || lower.contains('selam')) {
      return character.greeting;
    }
    if (lower.contains('hikaye')) {
      return 'Bir varmış bir yokmuş, küçük bir yıldız gökyüzünde kaybolmuş '
          'arkadaşını arıyormuş...';
    }
    if (lower.contains('bilmece')) {
      return 'Sabah dört, öğlen iki, akşam üç ayak üstünde yürüyen nedir? '
          '(Cevap: İnsan!)';
    }
    if (lower.contains('fıkra')) {
      return 'Duydun mu, tavşan neden yola çıkmış? Karşı tarafa geçmek için!';
    }
    if (lower.contains('ingilizce') || lower.contains('english')) {
      return 'Hadi birlikte öğrenelim: "Merhaba" İngilizcede "Hello" demek!';
    }

    return 'Bunu bana biraz daha anlatır mısın? Seni dinliyorum!';
  }
}
