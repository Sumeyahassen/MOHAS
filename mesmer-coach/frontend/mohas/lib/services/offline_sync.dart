import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineSync {
  static Database? _db;
  static final storage = const FlutterSecureStorage();

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'mesmer_offline.db'),
      version: 1,
      onCreate: (db, version) {
        db.execute('CREATE TABLE pending_visits (id INTEGER PRIMARY KEY, data TEXT)');
      },
    );
    return _db!;
  }

  // Save visit offline
  static Future<void> saveOffline(Map<String, dynamic> visitData) async {
    final db = await database;
    await db.insert('pending_visits', {'data': jsonEncode(visitData)});
  }

  // Try to sync when online
  static Future<void> syncPending() async {
    final db = await database;
    final pending = await db.query('pending_visits');

    final token = await storage.read(key: 'token');
    final ip = 'http://YOUR_IP:5000';   // ←←← CHANGE TO YOUR REAL IP

    for (var row in pending) {
      try {
        final data = jsonDecode(row['data'] as String);
        final res = await http.post(
          Uri.parse('$ip/api/coaching-visits'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(data),
        );

        if (res.statusCode == 200) {
          await db.delete('pending_visits', where: 'id = ?', whereArgs: [row['id']]);
        }
      } catch (e) {}
    }
  }
}
