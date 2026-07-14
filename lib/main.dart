import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/character_selection/character_selection_screen.dart';

void main() {
  runApp(const AiBuddyKidsApp());
}

class AiBuddyKidsApp extends StatelessWidget {
  const AiBuddyKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Buddy Kids',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const CharacterSelectionScreen(),
    );
  }
}
