import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  /// INIT DATABASE
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'geofence.db');

    return await openDatabase(
      path,
      version: 4, // 🔼 NAIKKAN VERSI
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            password TEXT,
            nama TEXT,
            isLogin INTEGER,
            profileImage TEXT
            pin TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        /// MIGRASI KE V2
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN profileImage TEXT'
          );
        }

        /// MIGRASI KE V3 (TAMBAH NAMA)
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN nama TEXT'
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN pin TEXT'
          );
        }
      },
    );
  }

  /// REGISTER USER (WAJIB NAMA)
  static Future<void> register(
    String email,
    String password,
    String nama,
  ) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'email': email,
        'password': password,
        'nama': nama,
        'isLogin': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// LOGIN USER
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final db = await database;

    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (res.isNotEmpty) {
      await db.update(
        'users',
        {'isLogin': 1},
        where: 'id = ?',
        whereArgs: [res.first['id']],
      );
      return res.first;
    }
    return null;
  }

  /// LOGOUT
  static Future<void> logout() async {
    final db = await database;
    await db.update('users', {'isLogin': 0});
  }
}
