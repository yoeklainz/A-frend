import 'package:flutter/material.dart';
import '../../../core/models/character.dart';

/// Lottie/harici animasyon dosyası GEREKTİRMEYEN, tamamen Flutter'ın
/// kendi animasyon sistemiyle çizilen karakter avatarı.
///
/// Neden böyle: dışarıdan .json animasyon dosyası eklemek zorunlu olmasın,
/// proje "assets/animations/" boş olsa bile derlensin ve çalışsın diye.
/// İleride gerçek Lottie dosyaları eklersen bu widget'ı kolayca
/// `Lottie.asset(character.animationAsset)` ile değiştirebilirsin.
///
/// Duygu durumuna göre:
/// - happy/excited: hafif zıplama + büyüme
/// - sleepy: yavaş "nefes alma" efekti
/// - surprised: ani büyüme
/// - curious: hafif sağa-sola sallanma
class CharacterAvatar extends StatefulWidget {
  final Character character;
  final EmotionState emotion;
  final double size;

  const CharacterAvatar({
    super.key,
    required this.character,
    required this.emotion,
    this.size = 220,
  });

  @override
  State<CharacterAvatar> createState() => _CharacterAvatarState();
}

class _CharacterAvatarState extends State<CharacterAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Map<CharacterType, Color> _characterColors = {
    CharacterType.robot: Color(0xFF4CC9F0),
    CharacterType.cat: Color(0xFFFFB4A2),
    CharacterType.dog: Color(0xFFE9C46A),
    CharacterType.alien: Color(0xFF90E0EF),
    CharacterType.dinosaur: Color(0xFF74C69D),
    CharacterType.panda: Color(0xFFB8B8B8),
    CharacterType.owl: Color(0xFFCDB4DB),
    CharacterType.cartoon: Color(0xFFFF9F1C),
  };

  static const Map<CharacterType, IconData> _characterIcons = {
    CharacterType.robot: Icons.smart_toy,
    CharacterType.cat: Icons.pets,
    CharacterType.dog: Icons.pets,
    CharacterType.alien: Icons.travel_explore,
    CharacterType.dinosaur: Icons.forest,
    CharacterType.panda: Icons.cruelty_free,
    CharacterType.owl: Icons.nightlight_round,
    CharacterType.cartoon: Icons.emoji_emotions,
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForEmotion(widget.emotion),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CharacterAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _controller.duration = _durationForEmotion(widget.emotion);
      _controller.repeat(reverse: true);
    }
  }

  Duration _durationForEmotion(EmotionState emotion) {
    switch (emotion) {
      case EmotionState.excited:
        return const Duration(milliseconds: 350);
      case EmotionState.happy:
        return const Duration(milliseconds: 600);
      case EmotionState.sleepy:
        return const Duration(milliseconds: 1800);
      case EmotionState.surprised:
        return const Duration(milliseconds: 250);
      case EmotionState.curious:
      case EmotionState.sad:
        return const Duration(milliseconds: 1000);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _characterColors[widget.character.type] ?? Theme.of(context).colorScheme.primary;
    final icon = _characterIcons[widget.character.type] ?? Icons.emoji_emotions;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0..1 arasında salınan değer
        double scale = 1.0;
        double angle = 0.0;
        double dy = 0.0;

        switch (widget.emotion) {
          case EmotionState.excited:
          case EmotionState.happy:
            dy = -8 * t; // yukarı-aşağı zıplama
            scale = 1.0 + 0.04 * t;
            break;
          case EmotionState.sleepy:
            scale = 1.0 + 0.03 * t; // yavaş nefes alma
            break;
          case EmotionState.surprised:
            scale = 1.0 + 0.08 * t;
            break;
          case EmotionState.curious:
          case EmotionState.sad:
            angle = 0.05 * (t - 0.5); // hafif sallanma
            break;
        }

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 4),
          ],
        ),
        child: Icon(icon, size: widget.size * 0.5, color: Colors.white),
      ),
    );
  }
}
