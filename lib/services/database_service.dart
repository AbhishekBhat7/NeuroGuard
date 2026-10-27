import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'neuroguard.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY,
            patientName TEXT NOT NULL,
            patientAge TEXT NOT NULL,
            patientLocation TEXT NOT NULL,
            patientGender TEXT NOT NULL,
            patientPhone TEXT NOT NULL,
            caretakerEmail TEXT NOT NULL,
            caretakerName TEXT NOT NULL,
            caretakerPhone TEXT NOT NULL,
            caretakerGender TEXT NOT NULL
          )
        ''');

        // Insert initial default profile
        final defaultProfile = UserProfile.defaultProfile();
        await db.insert('profile', defaultProfile.toMap());
      },
    );
  }

  Future<UserProfile> getProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    } else {
      final defaultProfile = UserProfile.defaultProfile();
      await db.insert('profile', defaultProfile.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return defaultProfile;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

