import 'package:flutter/material.dart';
import '../../core/models/character.dart';
import '../home/home_screen.dart';

/// Çocuğun karakterlerden (robot, kedi, köpek...) birini seçtiği ekran.
/// Büyük, dokunması kolay kartlar kullanır.
class CharacterSelectionScreen extends StatelessWidget {
  const CharacterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaşını Seç')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: CharacterCatalog.all.length,
        itemBuilder: (context, index) {
          final character = CharacterCatalog.all[index];
          return _CharacterCard(character: character);
        },
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  const _CharacterCard({required this.character});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HomeScreen(character: character),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Gerçek animasyon dosyası bağlandığında Lottie widget'ı kullan.
            const Icon(Icons.emoji_emotions, size: 64),
            const SizedBox(height: 8),
            Text(
              character.displayName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
