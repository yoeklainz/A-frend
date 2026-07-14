/// Uygulamadaki her yapay zeka karakterini (Robot, Kedi, Köpek vb.) temsil eder.
/// Yeni bir karakter eklemek için sadece bu listeye yeni bir CharacterType
/// ve karşılığında CharacterCatalog.all içine bir kayıt eklemen yeterli.
library character_model;

enum CharacterType { robot, cat, dog, alien, dinosaur, panda, owl, cartoon }

enum EmotionState { happy, sad, excited, curious, sleepy, surprised }

class Character {
  final CharacterType type;
  final String displayName;
  final String animationAsset; // Lottie/Rive dosya yolu
  final String voiceId; // TTS motorunda kullanılacak ses profili
  final double speechRate; // Konuşma hızı (karaktere özgü ton için)
  final double speechPitch; // Ses tonu (perde)
  final String greeting; // Karaktere özgü selamlama cümlesi

  const Character({
    required this.type,
    required this.displayName,
    required this.animationAsset,
    required this.voiceId,
    required this.speechRate,
    required this.speechPitch,
    required this.greeting,
  });
}

/// Tüm karakterlerin merkezi kataloğu.
class CharacterCatalog {
  static const List<Character> all = [
    Character(
      type: CharacterType.robot,
      displayName: 'Robo',
      animationAsset: 'assets/animations/robot.json',
      voiceId: 'tr-TR-robotic',
      speechRate: 0.45,
      speechPitch: 0.8,
      greeting: 'Merhaba! Ben Robo, bugün seninle oynamaya hazırım!',
    ),
    Character(
      type: CharacterType.cat,
      displayName: 'Minnoş',
      animationAsset: 'assets/animations/cat.json',
      voiceId: 'tr-TR-soft',
      speechRate: 0.5,
      speechPitch: 1.3,
      greeting: 'Miyav! Merhaba küçük dostum, günün nasıl geçiyor?',
    ),
    Character(
      type: CharacterType.dog,
      displayName: 'Karabaş',
      animationAsset: 'assets/animations/dog.json',
      voiceId: 'tr-TR-cheerful',
      speechRate: 0.55,
      speechPitch: 1.0,
      greeting: 'Hav hav! Seni gördüğüme çok sevindim!',
    ),
    Character(
      type: CharacterType.alien,
      displayName: 'Zorbi',
      animationAsset: 'assets/animations/alien.json',
      voiceId: 'tr-TR-quirky',
      speechRate: 0.5,
      speechPitch: 1.1,
      greeting: 'Bip bop! Uzaydan geldim, seninle tanışmak isterim!',
    ),
    Character(
      type: CharacterType.dinosaur,
      displayName: 'Rex',
      animationAsset: 'assets/animations/dinosaur.json',
      voiceId: 'tr-TR-deep',
      speechRate: 0.45,
      speechPitch: 0.7,
      greeting: 'Grrr! Merhaba, ben dostane bir dinozorum!',
    ),
    Character(
      type: CharacterType.panda,
      displayName: 'Pofuduk',
      animationAsset: 'assets/animations/panda.json',
      voiceId: 'tr-TR-gentle',
      speechRate: 0.48,
      speechPitch: 1.0,
      greeting: 'Merhaba! Birlikte harika vakit geçireceğiz.',
    ),
    Character(
      type: CharacterType.owl,
      displayName: 'Bilge',
      animationAsset: 'assets/animations/owl.json',
      voiceId: 'tr-TR-wise',
      speechRate: 0.42,
      speechPitch: 0.9,
      greeting: 'Uhu! Bugün sana neler öğretebilirim acaba?',
    ),
    Character(
      type: CharacterType.cartoon,
      displayName: 'Neşeli',
      animationAsset: 'assets/animations/cartoon.json',
      voiceId: 'tr-TR-fun',
      speechRate: 0.55,
      speechPitch: 1.2,
      greeting: 'Merhaba! Hadi birlikte eğlenelim!',
    ),
  ];

  static Character byType(CharacterType type) =>
      all.firstWhere((c) => c.type == type, orElse: () => all.first);
}
