import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';

/// Tüm yerel veriyi (profiller, ayarlar, kullanım süresi logu) yöneten servis.
/// Tekil (singleton) olarak kullanılır; tüm veri cihaz içinde kalır.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_buddy_kids.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            is_parent INTEGER NOT NULL,
            age_years INTEGER NOT NULL,
            preferred_character TEXT NOT NULL,
            face_embedding TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE usage_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL,
            session_start TEXT NOT NULL,
            session_end TEXT,
            topic_summary TEXT,
            FOREIGN KEY (profile_id) REFERENCES profiles (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE parental_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            daily_limit_minutes INTEGER NOT NULL DEFAULT 60,
            pin_code TEXT NOT NULL,
            content_filter_level TEXT NOT NULL DEFAULT 'strict'
          )
        ''');
      },
    );
  }

  // ---- Profil işlemleri ----

  Future<int> insertProfile(UserProfile profile) async {
    final db = await database;
    return db.insert('profiles', profile.toMap());
  }

  Future<List<UserProfile>> getAllProfiles() async {
    final db = await database;
    final rows = await db.query('profiles');
    return rows.map((r) => UserProfile.fromMap(r)).toList();
  }

  Future<void> deleteProfile(int id) async {
    final db = await database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Kullanım süresi (ebeveyn kontrolü için) ----

  Future<int> startSession(int profileId) async {
    final db = await database;
    return db.insert('usage_log', {
      'profile_id': profileId,
      'session_start': DateTime.now().toIso8601String(),
    });
  }

  Future<void> endSession(int sessionId, {String? topicSummary}) async {
    final db = await database;
    await db.update(
      'usage_log',
      {
        'session_end': DateTime.now().toIso8601String(),
        'topic_summary': topicSummary,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Bugün bu profilin toplam kullanım süresini dakika olarak döner.
  Future<int> getTodayUsageMinutes(int profileId) async {
    final db = await database;
    final todayStart = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.query(
      'usage_log',
      where: 'profile_id = ? AND session_start LIKE ?',
      whereArgs: [profileId, '$todayStart%'],
    );

    int totalMinutes = 0;
    for (final row in rows) {
      final start = DateTime.parse(row['session_start'] as String);
      final endRaw = row['session_end'] as String?;
      final end = endRaw != null ? DateTime.parse(endRaw) : DateTime.now();
      totalMinutes += end.difference(start).inMinutes;
    }
    return totalMinutes;
  }
}
