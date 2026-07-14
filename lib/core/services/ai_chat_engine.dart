import '../models/character.dart';

/// Gerçek bir AI modeline (bulut API veya cihaz üzerinde çalışan bir model)
/// bağlanan sınıfların uyması gereken arayüz. ChatService bu arayüzü
/// kullanır; hangi motorun (RemoteAiChatEngine, yerel bir model, vb.)
/// bağlı olduğunu bilmesine gerek yoktur.
abstract class AiChatEngine {
  /// [systemPrompt] karakterin kişiliğini, yaş uyarlamasını ve güvenlik
  /// kurallarını tanımlar. [userMessage] çocuğun söylediği şeydir.
  /// Ağ hatası veya API sorunu durumunda bir Exception fırlatmalıdır;
  /// ChatService bunu yakalayıp kural tabanlı yanıta geri döner.
  Future<String> generateReply({
    required String systemPrompt,
    required String userMessage,
    required List<ChatTurn> recentHistory,
  });
}

/// Kısa süreli sohbet geçmişi — modelin bağlamı takip edebilmesi için.
class ChatTurn {
  final String role; // 'user' veya 'assistant'
  final String content;
  const ChatTurn({required this.role, required this.content});
}
