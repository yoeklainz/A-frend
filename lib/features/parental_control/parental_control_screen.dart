import 'package:flutter/material.dart';
import '../person_enrollment/person_enrollment_screen.dart';

/// Ebeveynin günlük kullanım süresi limiti belirlediği, içerik filtresi
/// seviyesini ayarladığı ve profilleri yönettiği ekran.
/// PIN doğrulaması yapılmadan bu ekrana girilememelidir
/// (giriş noktasında ayrı bir PIN doğrulama widget'ı eklenmeli).
class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  double _dailyLimitMinutes = 60;
  String _filterLevel = 'strict';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ebeveyn Kontrol Paneli')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Günlük Kullanım Süresi Limiti', style: Theme.of(context).textTheme.headlineMedium),
          Slider(
            value: _dailyLimitMinutes,
            min: 15,
            max: 180,
            divisions: 11,
            label: '${_dailyLimitMinutes.round()} dk',
            onChanged: (value) => setState(() => _dailyLimitMinutes = value),
          ),
          const SizedBox(height: 24),
          Text('İçerik Filtre Seviyesi', style: Theme.of(context).textTheme.headlineMedium),
          RadioListTile(
            title: const Text('Sıkı (önerilen)'),
            value: 'strict',
            groupValue: _filterLevel,
            onChanged: (value) => setState(() => _filterLevel = value!),
          ),
          RadioListTile(
            title: const Text('Standart'),
            value: 'standard',
            groupValue: _filterLevel,
            onChanged: (value) => setState(() => _filterLevel = value!),
          ),
          const SizedBox(height: 24),
          Text('Aile Üyeleri', style: Theme.of(context).textTheme.headlineMedium),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Yeni Aile Üyesi Ekle'),
            subtitle: const Text('Yüz tanıma için isim ve yüz kaydı'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PersonEnrollmentScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          // TODO: DatabaseService.instance ile parental_settings tablosuna
          // (daily_limit_minutes, content_filter_level) kaydet.
          ElevatedButton(
            onPressed: () {
              // Ayarları kaydet ve geri dön.
              Navigator.of(context).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
