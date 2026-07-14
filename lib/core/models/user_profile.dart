import 'dart:convert';
import 'character.dart';

/// Aile içindeki her kişi (çocuk veya ebeveyn) için profil.
/// faceEmbedding: FaceRecognitionService tarafından çıkarılan yüz vektörü
/// (ör. 192 boyutlu float listesi). Bu veri asla sunucuya/buluta
/// gönderilmez, sadece yerel veritabanında JSON olarak saklanır —
/// çocuk güvenliği ve gizlilik gereği.
class UserProfile {
  final int? id;
  final String name;
  final bool isParent;
  final int ageYears; // yaşa uygun cevap üretmek için
  final CharacterType preferredCharacter;
  final List<double>? faceEmbedding;
  final DateTime createdAt;

  UserProfile({
    this.id,
    required this.name,
    required this.isParent,
    required this.ageYears,
    this.preferredCharacter = CharacterType.robot,
    this.faceEmbedding,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'is_parent': isParent ? 1 : 0,
        'age_years': ageYears,
        'preferred_character': preferredCharacter.name,
        'face_embedding': faceEmbedding != null ? jsonEncode(faceEmbedding) : null,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as int?,
        name: map['name'] as String,
        isParent: (map['is_parent'] as int) == 1,
        ageYears: map['age_years'] as int,
        preferredCharacter: CharacterType.values.firstWhere(
          (e) => e.name == map['preferred_character'],
          orElse: () => CharacterType.robot,
        ),
        faceEmbedding: map['face_embedding'] != null
            ? (jsonDecode(map['face_embedding'] as String) as List)
                .map((e) => (e as num).toDouble())
                .toList()
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

